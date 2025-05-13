enum AppointmentStatus { booked, completed, canceled }

class Appointment {
  final String id; // Unique appointment ID
  final String patientId;
  final String doctorId;
  final DateTime dateTime;
  AppointmentStatus status;
  final double fee;
  final bool isPaid;
  final String? notes; // Patient-added notes for history

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    this.status = AppointmentStatus.booked,
    required this.fee,
    this.isPaid = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'doctorId': doctorId,
    'dateTime': dateTime,
    'status': status.toString().split('.').last,
    'fee': fee,
    'isPaid': isPaid,
    'notes': notes,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    doctorId: json['doctorId'] as String,
    dateTime: DateTime.parse(json['dateTime']),
    status: AppointmentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
    ),
    fee: (json['fee'] as num).toDouble(),
    isPaid: json['isPaid'] as bool,
    notes: json['notes'] as String?,
  );
}