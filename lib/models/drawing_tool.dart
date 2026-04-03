import 'package:flutter/material.dart';

enum DrawingToolType { pen, sketch, marker, eraser }

class DrawingTool {
  final DrawingToolType type;
  final Color color;
  final double strokeWidth;
  final double opacity;

  const DrawingTool({
    required this.type,
    this.color = Colors.white,
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
  });

  DrawingTool copyWith({
    DrawingToolType? type,
    Color? color,
    double? strokeWidth,
    double? opacity,
  }) =>
      DrawingTool(
        type: type ?? this.type,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        opacity: opacity ?? this.opacity,
      );
}
