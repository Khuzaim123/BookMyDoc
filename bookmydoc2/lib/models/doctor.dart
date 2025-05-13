import 'user.dart';

class Doctor extends User {
  final String specialty;
  final String qualifications;
  final String clinicAddress;
  final Map<String, String> workingHours; // e.g., {"Monday": "9:00-17:00"}
  final double? commissionRate; // Set by Admin (e.g., 10%)
  final double? rating;            // Add this
  final double? experience;           // Add this
  final double? consultationFee;   // Add this


  Doctor({
    required String id,
    required String name,
    required String email,
    required this.specialty,
    required this.qualifications,
    required this.clinicAddress,
    required this.workingHours,
    this.commissionRate,
    this.consultationFee,
    this.rating,
    this.experience
  }) : super(id: id, name: name, email: email, role: UserRole.doctor);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'specialty': specialty,
    'qualifications': qualifications,
    'clinicAddress': clinicAddress,
    'workingHours': workingHours,
    'commissionRate': commissionRate,
    'rating': rating,
    'experience': experience,
    'consultationFee': consultationFee
  };

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    specialty: json['specialty'] as String? ?? '', // Default to empty string if null
    qualifications: json['qualifications'] as String? ?? '', // Default to empty string if null
    clinicAddress: json['clinicAddress'] as String? ?? '', // Default to empty string if null
    workingHours: Map<String, String>.from(json['workingHours'] as Map<dynamic, dynamic>? ?? {}), // Handle null workingHours
    commissionRate: json['commissionRate']?.toDouble(),
    rating: json['rating'] as double?, // Allow null for optional fields
    experience: json['experience'] as double?, // Allow null for optional fields
    consultationFee: json['consultationFee'] as double?, // Allow null for optional fields
  );
}