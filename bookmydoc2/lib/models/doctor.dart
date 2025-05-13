import 'user.dart';

class Doctor extends User {
  final String specialty;
  final String qualifications;
  final String clinicAddress;
  final Map<String, String> workingHours; // e.g., {"Monday": "9:00-17:00"}
  final double? commissionRate; // Set by Admin (e.g., 10%)

  Doctor({
    required String id,
    required String name,
    required String email,
    required this.specialty,
    required this.qualifications,
    required this.clinicAddress,
    required this.workingHours,
    this.commissionRate,
  }) : super(id: id, name: name, email: email, role: UserRole.doctor);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'specialty': specialty,
    'qualifications': qualifications,
    'clinicAddress': clinicAddress,
    'workingHours': workingHours,
    'commissionRate': commissionRate,
  };

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    specialty: json['specialty'] as String,
    qualifications: json['qualifications'] as String,
    clinicAddress: json['clinicAddress'] as String,
    workingHours: Map<String, String>.from(json['workingHours'] as Map),
    commissionRate: json['commissionRate']?.toDouble(),
  );
}