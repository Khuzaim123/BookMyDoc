import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageScreen extends StatefulWidget {
  final String doctorId;

  const MessageScreen({super.key, required this.doctorId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final List<Message> messages = [
    Message(
      id: 'msg1',
      senderId: 'patient1',
      receiverId: 'doc1',
      content: 'Hi, I need to discuss my test results.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: true,
    ),
    Message(
      id: 'msg2',
      senderId: 'doc1',
      receiverId: 'patient1',
      content: 'Sure, please share the details.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        messages.add(
          Message(
            id: 'msg${messages.length + 1}',
            senderId: 'patient1',
            receiverId: widget.doctorId,
            content: _messageController.text,
            timestamp: DateTime.now(),
          ),
        );
        _messageController.clear();
      });
    }
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
        title: Text(
          'Dr. ${widget.doctorId == 'doc1' ? 'John Smith' : 'Jane Doe'}', // Dummy name
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSentByPatient = message.senderId == 'patient1';
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: Align(
                    alignment: isSentByPatient ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      decoration: BoxDecoration(
                        color: isSentByPatient ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)],
                      ),
                      child: Text(
                        message.content,
                        style: GoogleFonts.poppins(
                          color: isSentByPatient ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input
          FadeInDown(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hintText: 'Type a message...',
                      controller: _messageController,
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
          ),
        ],
      ),
    );
  }
}