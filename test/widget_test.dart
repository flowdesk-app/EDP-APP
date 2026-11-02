import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/main.dart';

void main() {
  testWidgets('FlowDesk smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowDeskApp());
    expect(find.byType(FlowDeskApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
