import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  test('test serialization and deserialization', () {
    try {
      var line = SimpleLine();
      line.paint = Paint()..color = Colors.red;
      line.path.lineTo(100, 100);
      var json = line.toJson();
      print('SimpleLine JSON: \n${jsonEncode(json)}');
      
      // Attempt to load from JSON
      var loaded = SimpleLine.fromJson(json);
      print('Successfully loaded line!');
    } catch (e, stacktrace) {
      print('Deserialization failed: $e\n$stacktrace');
      throw e;
    }
  });
}
