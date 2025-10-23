import 'package:flutter_test/flutter_test.dart';
import 'package:client_web/main.dart';

void main() {
  testWidgets('Homepage builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ThreeSanhApp());

    // Brand in navbar
    expect(find.text('3 SÀNH'), findsOneWidget);

    // CTA appears (navbar or hero)
    expect(find.text('ĐẶT BÀN'), findsWidgets);
  });
}
