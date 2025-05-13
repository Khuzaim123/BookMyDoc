class AppFeedback {
  final String id;
  final String patientId;
  final String content;
  final DateTime submittedAt;

  AppFeedback({
    required this.id,
    required this.patientId,
    required this.content,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'content': content,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory AppFeedback.fromJson(Map<String, dynamic> json) => AppFeedback(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    content: json['content'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
  );
}