class Patient {
  final String id;
  String name;
  String email;
  String phone; // Added

  Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    name: json['name'] as String? ?? '', // Default to empty string if null
    email: json['email'] as String? ?? '', // Default to empty string if null
    phone: json['phone'] as String? ?? '', // Default to empty string if null
  );
}