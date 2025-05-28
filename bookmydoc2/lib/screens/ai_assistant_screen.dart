import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import convert for JSON encoding/decoding

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _queryController = TextEditingController();
  final List<Map<String, String>> chatMessages = [
    {'role': 'assistant', 'content': 'Hello! How can I assist you today?'},
  ];

  bool _isLoadingResponse = false; // To manage loading state for AI response

  // **Replace with your actual OpenRouter API Key**
  static const String _openRouterApiKey =
      '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  // Function to send message to OpenRouter API
  Future<void> _sendToOpenRouter(String message) async {
    if (_openRouterApiKey == '<YOUR_OPENROUTER_API_KEY>') {
      // Show an error if API key is not set
      setState(() {
        chatMessages.add({
          'role': 'assistant',
          'content':
              'Error: OpenRouter API key is not set. Please replace <YOUR_OPENROUTER_API_KEY> with your key.',
        });
        _isLoadingResponse = false;
      });
      return;
    }

    setState(() {
      _isLoadingResponse = true;
    });

    try {
      final headers = {
        'Authorization': 'Bearer $_openRouterApiKey',
        'Content-Type': 'application/json',
        // Optional headers:
        // 'HTTP-Referer': '<YOUR_SITE_URL>',
        // 'X-Title': '<YOUR_SITE_NAME>',
      };

      // Construct the messages list including previous messages for context
      final messagesPayload =
          chatMessages
              .map((msg) => {'role': msg['role'], 'content': msg['content']})
              .toList();
      // Add the current user message to the payload
      messagesPayload.add({'role': 'user', 'content': message});

      final body = jsonEncode({
        'model':
            'deepseek/deepseek-chat', // Using deepseek-chat as it's generally preferred over r1 for conversations
        'messages': messagesPayload,
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Assuming the response structure is similar to OpenAI chat completions
        final aiResponse = jsonResponse['choices'][0]['message']['content'];
        setState(() {
          chatMessages.add({'role': 'assistant', 'content': aiResponse});
        });
      } else {
        // Handle non-200 status codes
        print('API Error: ${response.statusCode}');
        print('API Error Body: ${response.body}');
        setState(() {
          chatMessages.add({
            'role': 'assistant',
            'content': 'Error: Failed to get response from AI.',
          });
        });
      }
    } catch (e) {
      // Handle network or other errors
      print('Error sending message to API: $e');
      setState(() {
        chatMessages.add({
          'role': 'assistant',
          'content': 'Error: Could not connect to the AI service.',
        });
      });
    } finally {
      setState(() {
        _isLoadingResponse = false;
      });
    }
  }

  void _askQuestion() {
    final userMessage = _queryController.text.trim();
    if (userMessage.isNotEmpty) {
      // Add the user message to the chat immediately
      setState(() {
        chatMessages.add({'role': 'user', 'content': userMessage});
        _queryController.clear();
      });
      // Send the message to the API
      _sendToOpenRouter(userMessage);
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
          'AI Assistant',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount:
                  chatMessages.length +
                  (_isLoadingResponse
                      ? 1
                      : 0), // Add space for loading indicator
              itemBuilder: (context, index) {
                if (index == chatMessages.length && _isLoadingResponse) {
                  // Display loading indicator as the last item
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.smallPadding,
                      ),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                final message = chatMessages[index];
                final isUser =
                    message['role'] == 'user'; // Use 'role' to determine sender
                return FadeInUp(
                  delay: Duration(
                    milliseconds: index * 50,
                  ), // Reduced delay for smoother animation
                  child: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSizes.smallPadding,
                      ),
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        message['content']!,
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
                      enabled:
                          !_isLoadingResponse, // Disable input while loading
                    ),
                  ),
                  const SizedBox(width: AppSizes.defaultPadding),
                  _isLoadingResponse
                      ? CircularProgressIndicator(
                        color: AppColors.primary,
                      ) // Show loading on send button
                      : IconButton(
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
