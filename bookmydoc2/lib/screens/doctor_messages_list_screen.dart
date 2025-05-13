import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorMessagesListScreen extends StatelessWidget {
   DoctorMessagesListScreen({super.key});

  // Dummy data
  final List<Patient> patients = [
    Patient(id: 'patient1', name: 'Alice Johnson', email: 'alice@example.com', phone: '+1234567890'),
    Patient(id: 'patient2', name: 'Bob Smith', email: 'bob@example.com', phone: '+1234567891'),
  ];

  final List<Message> messages = [
    Message(
      id: 'msg1',
      senderId: 'patient1',
      receiverId: 'doc1',
      content: 'Hello, I have a question about my appointment.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
    ),
    Message(
      id: 'msg2',
      senderId: 'patient2',
      receiverId: 'doc1',
      content: 'Can you review my latest test results?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group messages by patient
    final Map<String, List<Message>> messagesByPatient = {};
    for (var message in messages) {
      final patientId = message.senderId;
      if (!messagesByPatient.containsKey(patientId)) {
        messagesByPatient[patientId] = [];
      }
      messagesByPatient[patientId]!.add(message);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: messagesByPatient.isEmpty
          ? Center(
        child: FadeInUp(
          child: Text(
            'No messages yet',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        itemCount: messagesByPatient.keys.length,
        itemBuilder: (context, index) {
          final patientId = messagesByPatient.keys.elementAt(index);
          final patientMessages = messagesByPatient[patientId]!;
          final patient = patients.firstWhere(
                (p) => p.id == patientId,
            orElse: () => Patient(id: '', name: 'Unknown', email: '', phone: ''),
          );
          final latestMessage = patientMessages.reduce((a, b) =>
          a.timestamp.isAfter(b.timestamp) ? a : b);
          final unreadCount = patientMessages.where((m) => !m.isRead).length;

          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: CustomCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    patient.name[0],
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  patient.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  latestMessage.content,
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: unreadCount > 0
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
                  Navigator.pushNamed(context ,'${RouteNames.doctorMessage}?id=$patientId');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}