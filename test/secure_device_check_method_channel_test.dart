import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_device_check/secure_device_check_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSecureDeviceCheck();
  const channel = MethodChannel('secure_device_check');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isEmulator':
          return true;
        case 'isDeviceCompromised':
          return false;
        case 'isDeveloperOptionsEnabled':
          return {'developerOptions': true, 'usbDebugging': false};
        case 'enableScreenProtection':
          return null;
        case 'disableScreenProtection':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isEmulator returns bool from channel', () async {
    expect(await platform.isEmulator(), true);
  });

  test('isDeviceCompromised returns bool from channel', () async {
    expect(await platform.isDeviceCompromised(), false);
  });

  test('isDeveloperOptionsEnabled returns map from channel', () async {
    final result = await platform.isDeveloperOptionsEnabled();
    expect(result['developerOptions'], true);
    expect(result['usbDebugging'], false);
  });

  test('enableScreenProtection completes', () async {
    await platform.enableScreenProtection();
  });

  test('disableScreenProtection completes', () async {
    await platform.disableScreenProtection();
  });
}
