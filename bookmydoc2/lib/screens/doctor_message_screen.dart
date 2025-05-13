import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorMessageScreen extends StatefulWidget {
  final String patientId;

  const DoctorMessageScreen({super.key, required this.patientId});

  @override
  State<DoctorMessageScreen> createState() => _DoctorMessageScreenState();
}

class _DoctorMessageScreenState extends State<DoctorMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Dummy data
  final Patient patient = Patient(
    id: 'patient1',
    name: 'Alice Johnson',
    email: 'alice@example.com',
    phone: '+1234567890',
  );

  final List<Message> messages = [
    Message(
      id: 'msg1',
      senderId: 'patient1',
      receiverId: 'doc1',
      content: 'Hello, I have a question about my appointment.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: true,
    ),
    Message(
      id: 'msg2',
      senderId: 'doc1',
      receiverId: 'patient1',
      content: 'Of course, what would you like to know?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: true,
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        messages.add(Message(
          id: 'msg${messages.length + 1}',
          senderId: 'doc1',
          receiverId: widget.patientId,
          content: _messageController.text,
          timestamp: DateTime.now(),
          isRead: false,
        ));
        _messageController.clear();
      });
      // Scroll to the bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                patient.name[0],
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.defaultPadding),
            Text(
              patient.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: FadeInUp(
                child: Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSentByDoctor = message.senderId == 'doc1';
                return FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  child: Align(
                    alignment: isSentByDoctor ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      decoration: BoxDecoration(
                        color: isSentByDoctor
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isSentByDoctor
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: AppSizes.smallPadding),
                          Text(
                            message.timestamp.toString().substring(11, 16),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: 'Type a message...',
                    controller: _messageController,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: AppSizes.defaultPadding),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}