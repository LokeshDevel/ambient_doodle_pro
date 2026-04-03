import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  var line = SimpleLine();
  line.paint = Paint()..color = Colors.red;
  var json = line.toJson();
  print('SimpleLine: ${jsonEncode(json)}');
}
