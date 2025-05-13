class HealthTip {
  final String id; // Unique tip ID
  final String title; // e.g., "Stay Hydrated"
  final String content; // e.g., "Drink 8 glasses of water daily"
  final DateTime createdAt;

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HealthTip.fromJson(Map<String, dynamic> json) => HealthTip(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}