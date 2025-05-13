import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, pdf, document, file }

class Message {
  final String id; // Unique message ID
  final String senderId; // User ID (Patient or Doctor)
  final String receiverId; // User ID (Patient or Doctor)
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type; // New field for message type
  final String? fileName; // Optional for file messages
  final String? fileUrl; // Added for file storage URL

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text, // Default to text message
    this.fileName,
    this.fileUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'type': type.toString(),
    'fileName': fileName,
    'fileUrl': fileUrl,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    receiverId: json['receiverId'] as String,
    content: json['content'] as String,
    timestamp:
        json['timestamp'] is Timestamp
            ? (json['timestamp'] as Timestamp).toDate()
            : json['timestamp'] is String
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
    isRead: json['isRead'] as bool,
    type: MessageType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => MessageType.text,
    ),
    fileName: json['fileName'] as String?,
    fileUrl: json['fileUrl'] as String?,
  );
}
