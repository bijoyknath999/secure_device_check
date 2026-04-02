import 'package:flutter_test/flutter_test.dart';
import 'package:secure_device_check/secure_device_check.dart';
import 'package:secure_device_check/secure_device_check_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSecureDeviceCheckPlatform
    with MockPlatformInterfaceMixin
    implements SecureDeviceCheckPlatform {
  bool emulator = false;
  bool compromised = false;
  Map<String, bool> devOptions = {
    'developerOptions': false,
    'usbDebugging': false,
  };
  bool screenProtectionEnabled = false;

  @override
  Future<bool> isEmulator() async => emulator;

  @override
  Future<bool> isDeviceCompromised() async => compromised;

  @override
  Future<Map<String, bool>> isDeveloperOptionsEnabled() async => devOptions;

  @override
  Future<void> enableScreenProtection() async {
    screenProtectionEnabled = true;
  }

  @override
  Future<void> disableScreenProtection() async {
    screenProtectionEnabled = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterSecurityGuard', () {
    late MockSecureDeviceCheckPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockSecureDeviceCheckPlatform();
      SecureDeviceCheckPlatform.instance = mockPlatform;
    });

    test('isEmulator returns false by default', () async {
      expect(await FlutterSecurityGuard.isEmulator(), false);
    });

    test('isEmulator returns true when on emulator', () async {
      mockPlatform.emulator = true;
      expect(await FlutterSecurityGuard.isEmulator(), true);
    });

    test('isDeviceCompromised returns false by default', () async {
      expect(await FlutterSecurityGuard.isDeviceCompromised(), false);
    });

    test('isDeviceCompromised returns true when compromised', () async {
      mockPlatform.compromised = true;
      expect(await FlutterSecurityGuard.isDeviceCompromised(), true);
    });

    test('isDeveloperOptionsEnabled returns false by default', () async {
      final result = await FlutterSecurityGuard.isDeveloperOptionsEnabled();
      expect(result['developerOptions'], false);
      expect(result['usbDebugging'], false);
    });

    test('isDeveloperOptionsEnabled returns true when enabled', () async {
      mockPlatform.devOptions = {
        'developerOptions': true,
        'usbDebugging': true,
      };
      final result = await FlutterSecurityGuard.isDeveloperOptionsEnabled();
      expect(result['developerOptions'], true);
      expect(result['usbDebugging'], true);
    });

    test('enableScreenProtection completes without error', () async {
      await FlutterSecurityGuard.enableScreenProtection();
      expect(mockPlatform.screenProtectionEnabled, true);
    });

    test('disableScreenProtection completes without error', () async {
      mockPlatform.screenProtectionEnabled = true;
      await FlutterSecurityGuard.disableScreenProtection();
      expect(mockPlatform.screenProtectionEnabled, false);
    });
  });
}
