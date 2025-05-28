import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DoctorMessagesListScreen extends StatefulWidget {
  const DoctorMessagesListScreen({super.key});

  @override
  State<DoctorMessagesListScreen> createState() =>
      _DoctorMessagesListScreenState();
}

class _DoctorMessagesListScreenState extends State<DoctorMessagesListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _fetchUserImageUrl(String userId) async {
    try {
      final userImageDoc =
          await _firestore.collection('userImages').doc(userId).get();
      if (userImageDoc.exists) {
        final imageData = userImageDoc.data() as Map<String, dynamic>;
        return imageData['imageUrl'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user image URL: $e');
      return null;
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          user == null
              ? const Center(child: Text('Not logged in'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('messages')
                        .where('receiverId', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: AppColors.error),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
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
                  final Map<String, List<Message>> messagesByPatient = {};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final message = Message.fromJson({
                      ...data,
                      'id': doc.id,
                      'timestamp':
                          (data['timestamp'] is Timestamp)
                              ? (data['timestamp'] as Timestamp)
                                  .toDate()
                                  .toIso8601String()
                              : data['timestamp'],
                    });
                    final patientId = message.senderId;
                    messagesByPatient.putIfAbsent(patientId, () => []);
                    messagesByPatient[patientId]!.add(message);
                  }
                  final patientIds = messagesByPatient.keys.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    itemCount: patientIds.length,
                    itemBuilder: (context, index) {
                      final patientId = patientIds[index];
                      final patientMessages = messagesByPatient[patientId]!;
                      final latestMessage = patientMessages.reduce(
                        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
                      );
                      final unreadCount =
                          patientMessages.where((m) => !m.isRead).length;
                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore.collection('users').doc(patientId).get(),
                        builder: (context, userSnapshot) {
                          String patientName = 'Unknown';
                          String? imageUrl;

                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final pdata =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            patientName = pdata['name'] ?? 'Unknown';
                          }

                          return FutureBuilder<String?>(
                            future: _fetchUserImageUrl(patientId),
                            builder: (context, imageSnapshot) {
                              if (imageSnapshot.connectionState ==
                                  ConnectionState.done) {
                                imageUrl = imageSnapshot.data;
                              }
                              return FadeInUp(
                                delay: Duration(milliseconds: index * 100),
                                child: CustomCard(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      backgroundImage:
                                          imageUrl != null
                                              ? CachedNetworkImageProvider(
                                                imageUrl!,
                                              )
                                              : null,
                                      child:
                                          imageUrl == null
                                              ? Text(
                                                patientName.isNotEmpty
                                                    ? patientName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      patientName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      latestMessage.content,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing:
                                        unreadCount > 0
                                            ? CircleAvatar(
                                              radius: 12,
                                              backgroundColor:
                                                  AppColors.primary,
                                              child: Text(
                                                unreadCount.toString(),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                            : null,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.doctorMessage,
                                        arguments: {'id': patientId},
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
