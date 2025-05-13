class DoctorAvailability {
  final String id; // Unique availability ID
  final String doctorId;
  final DateTime startTime; // e.g., "2025-04-06 10:00"
  final DateTime endTime; // e.g., "2025-04-06 10:30"
  final bool isBooked; // Whether this slot is taken

  DoctorAvailability({
    required this.id,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isBooked': isBooked,
  };

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) =>
      DoctorAvailability(
        id: json['id'] as String,
        doctorId: json['doctorId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        isBooked: json['isBooked'] as bool,
      );
}