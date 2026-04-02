// Integration test for secure_device_check plugin.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:secure_device_check/secure_device_check.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isEmulator returns a boolean', (WidgetTester tester) async {
    final result = await FlutterSecurityGuard.isEmulator();
    expect(result, isA<bool>());
  });

  testWidgets('isDeviceCompromised returns a boolean',
      (WidgetTester tester) async {
    final result = await FlutterSecurityGuard.isDeviceCompromised();
    expect(result, isA<bool>());
  });
}
