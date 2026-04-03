import 'package:flutter_test/flutter_test.dart';
import 'package:ambient_doodle_pro/main.dart';

void main() {
  test('App widget can be instantiated', () {
    const app = AmbientDoodleApp();
    expect(app, isA<AmbientDoodleApp>());
  });
}
