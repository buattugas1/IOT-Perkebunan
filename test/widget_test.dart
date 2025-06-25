import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_2/main.dart';

void main() {
  testWidgets('App build smoke test', (WidgetTester tester) async {
    // Build the main app widget and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verifikasi bahwa title AppBar muncul
    expect(find.text('MQTT Monitoring'), findsOneWidget);

    // Verifikasi bahwa tombol "Turn Lamp ON" muncul
    expect(find.text('Turn Lamp ON'), findsOneWidget);

    // Verifikasi bahwa tombol "Turn Lamp OFF" muncul
    expect(find.text('Turn Lamp OFF'), findsOneWidget);
  });
}
