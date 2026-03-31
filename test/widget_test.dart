import 'package:flutter_test/flutter_test.dart';
import 'package:corex_mobile/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CoreXApp());
    await tester.pumpAndSettle();

    expect(find.text('CoreX OS'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
