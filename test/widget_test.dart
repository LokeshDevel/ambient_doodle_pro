import 'package:flutter_test/flutter_test.dart';
import 'package:ambient_doodle_pro/main.dart';

void main() {
  testWidgets('App mounts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const AmbientDoodleApp());
    expect(find.byType(AmbientDoodleApp), findsOneWidget);
  });
}
