class Rating {
  final String id; // Unique rating ID
  final String patientId;
  final String doctorId;
  final int stars; // 1-5
  final String? review; // Optional text review
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.stars,
    this.review,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'doctorId': doctorId,
    'stars': stars,
    'review': review,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    doctorId: json['doctorId'] as String,
    stars: json['stars'] as int,
    review: json['review'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}