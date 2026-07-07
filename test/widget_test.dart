import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/main.dart';

void main() {
  testWidgets('FlowDesk smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowDeskApp());
    expect(find.text('FlowDesk'), findsOneWidget);
  });
}
