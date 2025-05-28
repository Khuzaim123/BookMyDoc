class UserImage {
  final String userId;
  final String imageUrl;

  UserImage({required this.userId, required this.imageUrl});

  // Factory constructor to create a UserImage from a Firestore document
  factory UserImage.fromFirestore(Map<String, dynamic> firestoreData) {
    return UserImage(
      userId: firestoreData['userId'] as String,
      imageUrl: firestoreData['imageUrl'] as String,
    );
  }

  // Method to convert UserImage to a JSON format for Firestore
  Map<String, dynamic> toFirestore() {
    return {'userId': userId, 'imageUrl': imageUrl};
  }
}
