import Flutter
import UIKit

public class SecureDeviceCheckPlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    private var secureTextField: UITextField?

    override init() {
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SecureDeviceCheckPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "secure_device_check",
            binaryMessenger: registrar.messenger()
        )
        instance.methodChannel = methodChannel
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isEmulator":
            result(checkIsEmulator())
        case "isDeviceCompromised":
            result(checkIsJailbroken())
        case "isDeveloperOptionsEnabled":
            // iOS does not expose developer settings to third-party apps
            result(["developerOptions": false, "usbDebugging": false])
        case "enableScreenProtection":
            enableScreenProtection()
            result(nil)
        case "disableScreenProtection":
            disableScreenProtection()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Emulator / Simulator Detection

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
            "/usr/share/jailbreak/injectme.plist",
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

    // MARK: - Screen Protection
    //
    // Uses a secure UITextField overlay to prevent content from appearing
    // in screenshots and screen recordings. When enabled, captured content
    // appears blank/black.

    private func enableScreenProtection() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let window = self.getKeyWindow() else { return }

            if self.secureTextField == nil {
                let textField = UITextField()
                textField.isSecureTextEntry = true
                textField.isUserInteractionEnabled = false
                window.addSubview(textField)
                textField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
                textField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
                self.secureTextField = textField

                if let secureLayer = textField.layer.sublayers?.first {
                    secureLayer.frame = window.bounds
                    window.layer.superlayer?.addSublayer(secureLayer)
                }
            }
        }
    }

    private func disableScreenProtection() {
        DispatchQueue.main.async { [weak self] in
            self?.secureTextField?.removeFromSuperview()
            self?.secureTextField = nil
        }
    }

    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
}
