import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  test('test type-safe deserialization of integers', () {
    // This simulates exactly what Firebase gives us (stripping out `.0`)
    // Paint parameters like `color`, `blendMode`, `style`, `strokeJoin` are strictly ints.
    // Coordinate parameters like `x`, `y`, `strokeWidth`, `minPointDistance` are strictly doubles.
    final rawFirebaseJson = {
      "type": "SimpleLine",
      "minPointDistance": 2, // From 2.0
      "useBezierCurve": true,
      "path": {
        "fillType": 0,
        "steps": [
          {"type": "lineTo", "x": 100, "y": 100} // From 100.0
        ]
      },
      "paint": {
        "blendMode": 3,
        "color": 4294198070,
        "filterQuality": 0,
        "invertColors": false,
        "isAntiAlias": true,
        "strokeCap": 0,
        "strokeJoin": 0,
        "strokeWidth": 0, // From 0.0
        "style": 0
      }
    };
    
    
    try {
      final normalized = _normalizeNumbers(rawFirebaseJson);
      SimpleLine.fromJson(normalized as Map<String, dynamic>);
      print("SUCCESS! Safely loaded normalized JSON");
    } catch(e) {
      print("Still failed: $e");
    }
  });
}

dynamic _normalizeNumbers(dynamic node, [String? parentKey]) {
  if (node is Map) {
    final Map<String, dynamic> newMap = {};
    node.forEach((key, value) {
      newMap[key as String] = _normalizeNumbers(value, key as String);
    });
    return newMap;
  } else if (node is List) {
    return node.map((e) => _normalizeNumbers(e, parentKey)).toList();
  } else if (node is int) {
    final doubleFields = ['x', 'y', 'strokeWidth', 'minPointDistance'];
    if (parentKey != null && doubleFields.contains(parentKey)) {
      return node.toDouble();
    }
  }
  return node;
}
