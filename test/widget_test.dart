import 'package:flutter_test/flutter_test.dart';
import 'package:offline_posts_manager/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflinePostsApp());
    expect(find.text('Offline Posts Manager'), findsOneWidget);
  });
}
