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

class DoctorMessagesListScreen extends StatefulWidget {
  const DoctorMessagesListScreen({super.key});

  @override
  State<DoctorMessagesListScreen> createState() =>
      _DoctorMessagesListScreenState();
}

class _DoctorMessagesListScreenState extends State<DoctorMessagesListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                        'Error: \\${snapshot.error}',
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  // Group messages by patient
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
                            _firestore
                                .collection('patients')
                                .doc(patientId)
                                .get(),
                        builder: (context, patientSnapshot) {
                          String patientName = 'Unknown';
                          if (patientSnapshot.hasData &&
                              patientSnapshot.data!.exists) {
                            final pdata =
                                patientSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            patientName = pdata['name'] ?? 'Unknown';
                          }
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 100),
                            child: CustomCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    patientName.isNotEmpty
                                        ? patientName[0]
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    unreadCount > 0
                                        ? CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primary,
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
              ),
    );
  }
}
