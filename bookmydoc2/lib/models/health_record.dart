class HealthRecord {
  final String id; // Unique record ID
  final String patientId;
  final String fileUrl; // Firebase Storage URL
  final String category; // e.g., "Lab Reports", "Prescriptions"
  final DateTime uploadedAt;
  final List<String> sharedWith; // Doctor IDs with access

  HealthRecord({
    required this.id,
    required this.patientId,
    required this.fileUrl,
    required this.category,
    required this.uploadedAt,
    this.sharedWith = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'fileUrl': fileUrl,
    'category': category,
    'uploadedAt': uploadedAt.toIso8601String(),
    'sharedWith': sharedWith,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    fileUrl: json['fileUrl'] as String,
    category: json['category'] as String,
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    sharedWith: List<String>.from(json['sharedWith'] ?? []),
  );
}