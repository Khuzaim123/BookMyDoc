import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class MessagesListScreen extends StatelessWidget {
   MessagesListScreen({super.key});

  // Dummy conversation data
  final List<Map<String, dynamic>> conversations = [
    {
      'doctorId': 'doc1',
      'doctorName': 'Dr. John Smith',
      'latestMessage': Message(
        id: 'msg1',
        senderId: 'patient1',
        receiverId: 'doc1',
        content: 'Hi, I need to discuss my test results.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: true,
      ),
    },
    {
      'doctorId': 'doc2',
      'doctorName': 'Dr. Jane Doe',
      'latestMessage': Message(
        id: 'msg2',
        senderId: 'doc2',
        receiverId: 'patient1',
        content: 'Your appointment is confirmed.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: conversations.isEmpty
            ? Center(
          child: Text(
            'No messages yet',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        )
            : ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final convo = conversations[index];
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context , '${RouteNames.message}?id=${convo['doctorId']}'),
                child: CustomCard(
                  child: ListTile(
                    title: Text(
                      convo['doctorName'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      convo['latestMessage'].content,
                      style: GoogleFonts.poppins(
                        color: convo['latestMessage'].isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTimestamp(convo['latestMessage'].timestamp),
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
}