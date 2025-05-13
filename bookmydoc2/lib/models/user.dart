enum UserRole { patient, doctor, admin }

class User {
  final String id; // Unique ID (e.g., Firebase UID)
  final String name;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toString().split('.').last, // e.g., "patient"
  };

  // Create from JSON (Firestore data)
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == json['role'],
    ),
  );
}