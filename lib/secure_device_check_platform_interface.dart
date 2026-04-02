import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'secure_device_check_method_channel.dart';

/// The interface that implementations of secure_device_check must implement.
abstract class SecureDeviceCheckPlatform extends PlatformInterface {
  /// Constructs a SecureDeviceCheckPlatform.
  SecureDeviceCheckPlatform() : super(token: _token);

  static final Object _token = Object();

  static SecureDeviceCheckPlatform _instance = MethodChannelSecureDeviceCheck();

  /// The default instance of [SecureDeviceCheckPlatform] to use.
  static SecureDeviceCheckPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SecureDeviceCheckPlatform].
  static set instance(SecureDeviceCheckPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns `true` if the app is running on an emulator or simulator.
  Future<bool> isEmulator() {
    throw UnimplementedError('isEmulator() has not been implemented.');
  }

  /// Returns `true` if the device is rooted (Android) or jailbroken (iOS).
  Future<bool> isDeviceCompromised() {
    throw UnimplementedError('isDeviceCompromised() has not been implemented.');
  }

  /// Returns a map with developer options status.
  ///
  /// Keys: `developerOptions` (bool), `usbDebugging` (bool).
  /// On iOS, both are always `false`.
  Future<Map<String, bool>> isDeveloperOptionsEnabled() {
    throw UnimplementedError(
        'isDeveloperOptionsEnabled() has not been implemented.');
  }

  /// Enables screen protection (blocks screenshots and screen recording).
  ///
  /// On Android, sets `FLAG_SECURE` — screenshots appear black and screen
  /// recordings show a blank/black screen.
  ///
  /// On iOS, adds a secure text field overlay that obscures content
  /// in screenshots and screen recordings.
  Future<void> enableScreenProtection() {
    throw UnimplementedError(
        'enableScreenProtection() has not been implemented.');
  }

  /// Disables screen protection, restoring normal behavior.
  Future<void> disableScreenProtection() {
    throw UnimplementedError(
        'disableScreenProtection() has not been implemented.');
  }
}
