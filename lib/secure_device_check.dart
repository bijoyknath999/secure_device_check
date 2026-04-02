import 'secure_device_check_platform_interface.dart';

/// A comprehensive security suite for Flutter apps targeting banking
/// and fintech use cases.
///
/// Provides emulator detection, root/jailbreak detection, developer options
/// detection, and screen protection (blocks screenshots & screen recording)
/// for Android and iOS.
///
/// ```dart
/// // Check if running on emulator
/// final isEmu = await FlutterSecurityGuard.isEmulator();
///
/// // Check for root / jailbreak
/// final compromised = await FlutterSecurityGuard.isDeviceCompromised();
///
/// // Check developer options
/// final devOpts = await FlutterSecurityGuard.isDeveloperOptionsEnabled();
///
/// // Enable screen protection (blocks screenshots + screen recording)
/// await FlutterSecurityGuard.enableScreenProtection();
/// ```
class FlutterSecurityGuard {
  FlutterSecurityGuard._(); // Prevent instantiation

  /// Returns `true` if the app is running on an emulator (Android)
  /// or simulator (iOS).
  ///
  /// Uses multiple heuristics including build properties, hardware
  /// fingerprints, and compile-time checks to provide reliable detection.
  static Future<bool> isEmulator() {
    return SecureDeviceCheckPlatform.instance.isEmulator();
  }

  /// Returns `true` if the device is rooted (Android) or jailbroken (iOS).
  ///
  /// On Android, checks for the presence of `su` binary, Magisk, BusyBox,
  /// and unsafe system properties.
  ///
  /// On iOS, checks for Cydia, known jailbreak file paths, sandbox escape
  /// attempts, and writable system paths.
  static Future<bool> isDeviceCompromised() {
    return SecureDeviceCheckPlatform.instance.isDeviceCompromised();
  }

  /// Returns a map with developer options status.
  ///
  /// Returns `{'developerOptions': bool, 'usbDebugging': bool}`.
  ///
  /// On Android, checks `Settings.Global.DEVELOPMENT_SETTINGS_ENABLED`
  /// and `Settings.Global.ADB_ENABLED`.
  ///
  /// On iOS, both values are always `false` since iOS doesn't expose
  /// developer settings to third-party apps.
  static Future<Map<String, bool>> isDeveloperOptionsEnabled() {
    return SecureDeviceCheckPlatform.instance.isDeveloperOptionsEnabled();
  }

  /// Enables screen protection — blocks screenshots and screen recording.
  ///
  /// On Android, sets `FLAG_SECURE` on the Activity window, which:
  /// - Makes screenshots appear **black/blank**
  /// - Makes screen recordings show a **black screen**
  ///
  /// On iOS, adds a hidden secure text field overlay that causes captured
  /// content to appear blank in screenshots and screen recordings.
  static Future<void> enableScreenProtection() {
    return SecureDeviceCheckPlatform.instance.enableScreenProtection();
  }

  /// Disables screen protection, restoring normal screenshot and
  /// screen recording behavior.
  static Future<void> disableScreenProtection() {
    return SecureDeviceCheckPlatform.instance.disableScreenProtection();
  }
}
