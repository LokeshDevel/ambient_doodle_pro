// DrawingSession — serializable model for Firebase sync
class DrawingSession {
  final String id;
  final DateTime createdAt;
  final List<Map<String, dynamic>> points;

  DrawingSession({
    required this.id,
    required this.createdAt,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'points': points,
      };

  factory DrawingSession.fromJson(Map<String, dynamic> json) => DrawingSession(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        points: List<Map<String, dynamic>>.from(json['points'] as List),
      );
}
