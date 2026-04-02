import 'package:flutter_test/flutter_test.dart';

import 'package:secure_device_check_example/main.dart';

void main() {
  testWidgets('Security Dashboard renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify the app title is present
    expect(find.text('Secure Device Check'), findsOneWidget);
  });
}
