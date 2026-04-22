// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:monion_scanner/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MonionApp());
    expect(find.byType(MonionApp), findsOneWidget);
  });
}