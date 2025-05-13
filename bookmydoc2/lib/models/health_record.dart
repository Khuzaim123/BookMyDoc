import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRecord {
  final String id; // Unique record ID
  final String patientId;
  final String fileUrl; // Firebase Storage URL
  final String category; // e.g., "Lab Reports", "Prescriptions"
  final DateTime uploadedAt;
  final List<String> sharedWith; // Doctor IDs with access
  final String? fileName;

  HealthRecord({
    required this.id,
    required this.patientId,
    required this.fileUrl,
    required this.category,
    required this.uploadedAt,
    this.sharedWith = const [],
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'fileUrl': fileUrl,
    'category': category,
    'uploadedAt': uploadedAt,
    'sharedWith': sharedWith,
    'fileName': fileName,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    fileUrl: json['fileUrl'] as String,
    category: json['category'] as String,
    uploadedAt:
        json['uploadedAt'] is Timestamp
            ? (json['uploadedAt'] as Timestamp).toDate()
            : json['uploadedAt'] as DateTime,
    sharedWith: List<String>.from(json['sharedWith'] ?? []),
    fileName: json['fileName'] as String?,
  );
}
