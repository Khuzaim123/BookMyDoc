import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> conversations = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
  }

  Future<void> _fetchConversations() async {
    try {
      // Fetch all messages where the current user is a participant
      final messagesSnapshot =
          await _firestore
              .collection('messages')
              .where('participants', arrayContains: _currentUserId)
              .orderBy('timestamp', descending: true)
              .get();

      // Group messages by the other participant
      final Map<String, Map<String, dynamic>> conversationMap = {};
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.length != 2) continue; // Only 1-1 chats supported
        final otherUserId = participants.firstWhere(
          (id) => id != _currentUserId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) continue;
        // Only keep the latest message per conversation
        if (!conversationMap.containsKey(otherUserId)) {
          // Get the other user's name
          String otherUserName = 'Unknown';
          final otherUserDoc =
              await _firestore.collection('users').doc(otherUserId).get();
          if (otherUserDoc.exists) {
            otherUserName = otherUserDoc.data()?['name'] ?? 'Unknown';
          }
          final latestMessage = Message.fromJson({
            ...data,
            'id': doc.id,
            'timestamp':
                (data['timestamp'] is Timestamp)
                    ? (data['timestamp'] as Timestamp)
                        .toDate()
                        .toIso8601String()
                    : data['timestamp'],
          });
          conversationMap[otherUserId] = {
            'conversationId': doc.id,
            'userId': otherUserId,
            'userName': otherUserName,
            'latestMessage': latestMessage,
          };
        }
      }
      if (!mounted) return;
      setState(() {
        conversations = conversationMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      throw e;
    }
  }

  MessageType _getMessageTypeFromString(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'pdf':
        return MessageType.pdf;
      default:
        return MessageType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          user == null
              ? Center(child: Text('Not logged in'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('messages')
                        .where('participants', arrayContains: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: AppColors.error),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: FadeInUp(
                        child: Text(
                          'No messages yet',
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    );
                  }

                  // Group messages by the other participant
                  final Map<String, Map<String, dynamic>> conversationMap = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final participants = List<String>.from(
                      data['participants'] ?? [],
                    );
                    if (participants.length != 2) continue;
                    final otherUserId = participants.firstWhere(
                      (id) => id != user.uid,
                      orElse: () => '',
                    );
                    if (otherUserId.isEmpty) continue;
                    if (!conversationMap.containsKey(otherUserId)) {
                      conversationMap[otherUserId] = {
                        'conversationId': doc.id,
                        'userId': otherUserId,
                        'userName': 'Unknown',
                        'imageUrl': null,
                        'latestMessage': Message.fromJson({
                          ...data,
                          'id': doc.id,
                          'timestamp':
                              (data['timestamp'] is Timestamp)
                                  ? (data['timestamp'] as Timestamp)
                                      .toDate()
                                      .toIso8601String()
                                  : data['timestamp'],
                        }),
                      };
                    }
                  }

                  final conversations = conversationMap.values.toList();

                  return FutureBuilder(
                    future: _fetchUserDataForConversations(conversations),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.defaultPadding),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final otherUserId = conversation['userId'];
                          final otherUserName = conversation['userName'];
                          final imageUrl = conversation['imageUrl'];
                          final latestMessage =
                              conversation['latestMessage'] as Message;
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 100),
                            child: GestureDetector(
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    RouteNames.message,
                                    arguments: {
                                      'id': otherUserId,
                                      'conversationId':
                                          conversation['conversationId'],
                                      'name': otherUserName,
                                    },
                                  ),
                              child: CustomCard(
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary
                                            .withOpacity(0.1),
                                        backgroundImage:
                                            imageUrl != null
                                                ? CachedNetworkImageProvider(
                                                  imageUrl,
                                                )
                                                : null,
                                        child:
                                            imageUrl == null
                                                ? Text(
                                                  otherUserName.isNotEmpty
                                                      ? otherUserName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: GoogleFonts.poppins(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                : null,
                                      ),
                                      if (!latestMessage.isRead)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    otherUserName,
                                    style: GoogleFonts.poppins(
                                      fontWeight:
                                          !latestMessage.isRead
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (latestMessage.type ==
                                          MessageType.image)
                                        const Icon(
                                          Icons.image,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      if (latestMessage.type == MessageType.pdf)
                                        const Icon(
                                          Icons.picture_as_pdf,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      if (latestMessage.type ==
                                              MessageType.image ||
                                          latestMessage.type == MessageType.pdf)
                                        const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          latestMessage.type == MessageType.pdf
                                              ? (latestMessage.fileName ??
                                                  'PDF File')
                                              : latestMessage.content,
                                          style: GoogleFonts.poppins(
                                            color:
                                                latestMessage.isRead
                                                    ? AppColors.textLight
                                                    : AppColors.textPrimary,
                                            fontWeight:
                                                !latestMessage.isRead
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    _formatTimestamp(latestMessage.timestamp),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}';
  }

  Future<void> _fetchUserDataForConversations(
    List<Map<String, dynamic>> conversations,
  ) async {
    final firestore = FirebaseFirestore.instance;
    for (final conversation in conversations) {
      final otherUserId = conversation['userId'];
      final userDoc =
          await firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        conversation['userName'] = userDoc.data()?['name'] ?? 'Unknown';
      }
      final userImageDoc =
          await firestore.collection('userImages').doc(otherUserId).get();
      if (userImageDoc.exists) {
        final imageData = userImageDoc.data() as Map<String, dynamic>;
        conversation['imageUrl'] = imageData['imageUrl'];
      } else {
        conversation['imageUrl'] = null;
      }
    }
  }
}
