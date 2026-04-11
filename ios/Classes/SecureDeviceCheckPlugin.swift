import Flutter
import UIKit

public class SecureDeviceCheckPlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    
    // Screenshot detection
    private var screenshotObserver: NSObjectProtocol?
    
    // Screen protection
    private var secureTextField: UITextField?
    private var isProtectionEnabled = false
    
    // Screen recording
    private var privacyOverlay: UIView?
    private var recordingObserver: NSObjectProtocol?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SecureDeviceCheckPlugin()

        let channel = FlutterMethodChannel(
            name: "secure_device_check",
            binaryMessenger: registrar.messenger()
        )
        instance.methodChannel = channel

        // Screenshot detection — always active
        instance.screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak instance] _ in
            instance?.methodChannel?.invokeMethod("onScreenshotDetected", arguments: nil)
        }

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isEmulator":
            result(checkIsEmulator())
        case "isDeviceCompromised":
            result(checkIsJailbroken())
        case "isDeveloperOptionsEnabled":
            result(checkDeveloperOptions())
        case "enableScreenProtection":
            enableScreenProtection(result: result)
        case "disableScreenProtection":
            disableScreenProtection(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Screen Protection
    //
    // The UITextField internal structure differs across iOS versions:
    //   iOS 18+: subview[0]=_UITouchPassthroughView, subview[1]=_UITextLayoutCanvasView
    //   iOS 17:  subview[0]=_UITextLayoutCanvasView (possibly)
    //   iOS 15-16: may have different structure
    //
    // We search ALL subviews by class name for the secure canvas,
    // then fall back to layer-based approach if not found.

    private func enableScreenProtection(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { result(nil); return }
            guard !self.isProtectionEnabled, self.secureTextField == nil else {
                result(nil); return
            }
            guard let window = self.getKeyWindow() else {
                result(nil); return
            }
            guard let rootVC = window.rootViewController else {
                result(nil); return
            }

            let flutterView = rootVC.view!
            
            // Create full-screen secure text field
            let field = UITextField()
            field.isSecureTextEntry = true
            field.isUserInteractionEnabled = true
            field.frame = window.bounds
            field.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add to window to initialize internal view hierarchy
            window.addSubview(field)
            field.layoutIfNeeded()
            
            self.secureTextField = field
            
            // Find secure subview by class name (_UITextLayoutCanvasView)
            var secureView: UIView? = nil
            for sv in field.subviews {
                let className = String(describing: type(of: sv))
                if className.contains("TextLayoutCanvas") || className.contains("TextCanvas") {
                    secureView = sv
                    break
                }
            }
            
            // Fallback: use last subview
            if secureView == nil, field.subviews.count > 0 {
                secureView = field.subviews.last
            }
            
            // === Apply protection using the found secure view ===
            if let sv = secureView {
                // Expand to full screen
                sv.frame = window.bounds
                sv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                sv.isUserInteractionEnabled = true
                
                // Move Flutter view INTO the secure view
                sv.addSubview(flutterView)
                flutterView.frame = sv.bounds
                flutterView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.isProtectionEnabled = true
            } else {
                // Layer-based fallback
                
                if let superlayer = window.layer.superlayer {
                    field.layer.frame = window.bounds
                    superlayer.addSublayer(field.layer)
                    
                    // Try last sublayer first (canvas), then first
                    let targetLayer = field.layer.sublayers?.last ?? field.layer.sublayers?.first
                    if let secureLayer = targetLayer {
                        secureLayer.frame = window.bounds
                        secureLayer.addSublayer(window.layer)
                        self.isProtectionEnabled = true
                    }
                }
            }
            
            if self.isProtectionEnabled {
                // Screen recording overlay
                self.updateRecordingOverlay(window: window)
                self.recordingObserver = NotificationCenter.default.addObserver(
                    forName: UIScreen.capturedDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    guard let self = self, let win = self.getKeyWindow() else { return }
                    self.updateRecordingOverlay(window: win)
                }
            }
            
            result(nil)
        }
    }

    private func disableScreenProtection(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { result(nil); return }
            guard self.isProtectionEnabled else { result(nil); return }

            if let obs = self.recordingObserver {
                NotificationCenter.default.removeObserver(obs)
                self.recordingObserver = nil
            }

            self.privacyOverlay?.removeFromSuperview()
            self.privacyOverlay = nil

            // Move Flutter view BACK to the window
            if let window = self.findWindow(),
               let rootVC = window.rootViewController {
                window.addSubview(rootVC.view)
                rootVC.view.frame = window.bounds
                rootVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            
            // Restore layer if layer approach was used
            if let field = self.secureTextField,
               let parentLayer = field.layer.superlayer,
               let window = self.findWindow(),
               window.layer.superlayer !== parentLayer.superlayer {
                parentLayer.addSublayer(window.layer)
                field.layer.removeFromSuperlayer()
            }
            
            // Remove the secure text field
            self.secureTextField?.removeFromSuperview()
            self.secureTextField = nil
            self.isProtectionEnabled = false
            result(nil)
        }
    }

    private func updateRecordingOverlay(window: UIWindow) {
        if UIScreen.main.isCaptured {
            guard self.privacyOverlay == nil else { return }
            let overlay = UIView(frame: window.bounds)
            overlay.backgroundColor = .black
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.isUserInteractionEnabled = false
            window.addSubview(overlay)
            self.privacyOverlay = overlay
        } else {
            self.privacyOverlay?.removeFromSuperview()
            self.privacyOverlay = nil
        }
    }

    // MARK: - Window Helpers

    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .keyWindow
                ?? UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }

    private func findWindow() -> UIWindow? {
        return getKeyWindow() ?? UIApplication.shared.windows.first
    }

    // MARK: - Emulator Detection

    private func checkIsEmulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? ""
            }
        }
        if !machine.contains("iPhone") && !machine.contains("iPad") && !machine.contains("iPod") {
            if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
                return true
            }
        }
        return false
        #endif
    }

    // MARK: - Jailbreak Detection

    private func checkIsJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkJailbreakPaths()
            || checkCydiaURL()
            || checkSandboxViolation()
            || checkSymlinks()
            || checkWritableSystemPaths()
        #endif
    }

    private func checkJailbreakPaths() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/usr/libexec/cydia",
            "/usr/libexec/sftp-server",
            "/usr/share/jailbreak/injectme.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/etc/apt/sources.list.d/electra.list",
            "/etc/apt/sources.list.d/sileo.sources",
            "/.bootstrapped_electra",
            "/usr/lib/libjailbreak.dylib",
            "/jb/lzma",
            "/.cydia_no_stash",
            "/.installed_unc0ver",
            "/jb/offsets.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private func checkCydiaURL() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    private func checkSandboxViolation() -> Bool {
        do {
            let testString = "jailbreak_test"
            let testPath = "/private/jailbreak_test.txt"
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private func checkSymlinks() -> Bool {
        let symlinks = ["/var/lib/undecimus/apt", "/Applications"]
        for path in symlinks {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: path)
                if let type = attrs[.type] as? FileAttributeType, type == .typeSymbolicLink {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }

    private func checkWritableSystemPaths() -> Bool {
        let paths = ["/", "/root/", "/private/", "/jb/"]
        for path in paths {
            if FileManager.default.isWritableFile(atPath: path) {
                return true
            }
        }
        return false
    }

    // MARK: - Developer Options Detection

    private func checkDeveloperOptions() -> [String: Bool] {
        let debuggerAttached = isDebuggerAttached()
        let devProfile = hasDevelopmentProvisioningProfile()
        return [
            "developerOptions": debuggerAttached || devProfile,
            "usbDebugging": debuggerAttached
        ]
    }

    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if result != 0 { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    private func hasDevelopmentProvisioningProfile() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        guard let profilePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let profileData = try? Data(contentsOf: URL(fileURLWithPath: profilePath)),
              let profileString = String(data: profileData, encoding: .ascii) else {
            return false
        }
        let key = "<key>get-task-allow</key>"
        guard let range = profileString.range(of: key) else { return false }
        let afterKey = profileString[range.upperBound...]
        if afterKey.contains("<true/>") {
            if let trueRange = afterKey.range(of: "<true/>"),
               let nextKeyRange = afterKey.range(of: "<key>") {
                return trueRange.lowerBound < nextKeyRange.lowerBound
            }
            return true
        }
        return false
        #endif
    }

    deinit {
        if let obs = screenshotObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = recordingObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
