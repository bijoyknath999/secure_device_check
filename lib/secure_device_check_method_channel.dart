import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'secure_device_check_platform_interface.dart';

/// An implementation of [SecureDeviceCheckPlatform] that uses method channels.
class MethodChannelSecureDeviceCheck extends SecureDeviceCheckPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('secure_device_check');
  
  final StreamController<void> _screenshotController = StreamController<void>.broadcast();

  MethodChannelSecureDeviceCheck() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshotDetected') {
        _screenshotController.add(null);
      }
    });
  }

  @override
  Stream<void> get onScreenshotDetected => _screenshotController.stream;

  @override
  Future<bool> isEmulator() async {
    final result = await methodChannel.invokeMethod<bool>('isEmulator');
    return result ?? false;
  }

  @override
  Future<bool> isDeviceCompromised() async {
    final result =
        await methodChannel.invokeMethod<bool>('isDeviceCompromised');
    return result ?? false;
  }

  @override
  Future<Map<String, bool>> isDeveloperOptionsEnabled() async {
    final result = await methodChannel
        .invokeMethod<Map<Object?, Object?>>('isDeveloperOptionsEnabled');
    if (result == null) {
      return {'developerOptions': false, 'usbDebugging': false};
    }
    return result.map((key, value) =>
        MapEntry(key.toString(), value == true));
  }

  @override
  Future<void> enableScreenProtection() async {
    await methodChannel.invokeMethod<void>('enableScreenProtection');
  }

  @override
  Future<void> disableScreenProtection() async {
    await methodChannel.invokeMethod<void>('disableScreenProtection');
  }
}
