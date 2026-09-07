import 'package:flutter_test/flutter_test.dart';
import 'package:resqshield/main.dart';

void main() {
  testWidgets('ResQShield App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ResQShieldApp());
    expect(find.byType(ResQShieldApp), findsOneWidget);
  });
}
