import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/health_tip.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _queryController = TextEditingController();
  final List<Map<String, String>> chatMessages = [
    {'sender': 'AI', 'message': 'Hello! How can I assist you today?'},
  ];

  // Dummy health tips
  final List<HealthTip> healthTips = [
    HealthTip(
      id: 'tip1',
      title: 'Stay Hydrated',
      content: 'Drink at least 8 glasses of water daily to stay healthy.',
      createdAt: DateTime.now(),
    ),
    HealthTip(
      id: 'tip2',
      title: 'Exercise Regularly',
      content: 'Aim for 30 minutes of moderate exercise 5 days a week.',
      createdAt: DateTime.now(),
    ),
  ];

  void _askQuestion() {
    if (_queryController.text.isNotEmpty) {
      setState(() {
        chatMessages.add({'sender': 'User', 'message': _queryController.text});
        // Dummy AI response
        chatMessages.add({
          'sender': 'AI',
          'message': 'I’m not a real AI yet, but here’s a tip: ${healthTips.first.content}',
        });
        _queryController.clear();
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(context),
        ),
        title: Text('AI Assistant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                final isUser = message['sender'] == 'User';
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)],
                      ),
                      child: Text(
                        message['message']!,
                        style: GoogleFonts.poppins(
                          color: isUser ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Health Tips Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.defaultPadding),
            child: FadeInUp(
              child: Text(
                'Health Tips',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.defaultPadding),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.defaultPadding),
              itemCount: healthTips.length,
              itemBuilder: (context, index) {
                final tip = healthTips[index];
                return FadeInRight(
                  delay: Duration(milliseconds: index * 100),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppSizes.defaultPadding),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSizes.smallPadding),
                          Text(
                            tip.content,
                            style: GoogleFonts.poppins(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.defaultPadding),

          // Query Input
          FadeInDown(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hintText: 'Ask a health question...',
                      controller: _queryController,
                    ),
                  ),
                  const SizedBox(width: AppSizes.defaultPadding),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _askQuestion,
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