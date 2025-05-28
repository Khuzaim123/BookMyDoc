import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName; // Add doctor name parameter

  const MessageScreen({
    super.key,
    required this.doctorId,
    this.doctorName = 'Dr. Unknown', // Default value
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _messagesStream;
  List<Message> messages = [];
  bool isLoading = true;

  // Track the currently selected file (if any)
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  MessageType _selectedFileType = MessageType.text;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeMessagesStream();
  }

  void _initializeMessagesStream() {
    // Get current user ID (patient ID)
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Create a query to get messages between the current user and doctor
    // Ordered by timestamp
    _messagesStream =
        _firestore
            .collection('messages')
            .where(
              'participants',
              arrayContainsAny: [currentUserId, widget.doctorId],
            )
            .orderBy('timestamp', descending: false)
            .snapshots();

    // Listen to the stream
    _messagesStream.listen(
      (snapshot) {
        setState(() {
          messages =
              snapshot.docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Ensure senderId and receiverId are included in the participants array
                    final List<String> participants = List<String>.from(
                      data['participants'] ?? [],
                    );
                    if (!participants.contains(currentUserId) ||
                        !participants.contains(widget.doctorId)) {
                      return null; // Skip messages not between these two users
                    }

                    return Message(
                      id: doc.id,
                      senderId: data['senderId'] ?? '',
                      receiverId: data['receiverId'] ?? '',
                      content: data['content'] ?? '',
                      timestamp:
                          (data['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      isRead: data['isRead'] ?? false,
                      type: _getMessageTypeFromString(data['type'] ?? 'text'),
                      fileName: data['fileName'],
                    );
                  })
                  .where((message) => message != null)
                  .cast<Message>()
                  .toList();

          isLoading = false;
        });
      },
      onError: (error) {
        print("Error fetching messages: $error");
        setState(() {
          isLoading = false;
        });
      },
    );
  }

  // Convert string to MessageType enum
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

  // Convert MessageType enum to string
  String _getMessageTypeAsString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image';
      case MessageType.pdf:
        return 'pdf';
      default:
        return 'text';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Send a text message
  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null ||
        (_messageController.text.isEmpty && _selectedFile == null)) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      String? fileUrl;

      // Upload file if selected
      if (_selectedFile != null) {
        fileUrl = await _uploadFile();
      }

      if (!mounted) return;
      // Prepare the message data
      final messageData = {
        'senderId': currentUser.uid,
        'receiverId': widget.doctorId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'participants': [currentUser.uid, widget.doctorId],
      };

      // Add file details if a file was uploaded
      if (fileUrl != null && _selectedFile != null) {
        await _firestore.collection('messages').add({
          ...messageData,
          'content': fileUrl,
          'type': _getMessageTypeAsString(_selectedFileType),
          'fileName': _selectedFileName,
        });

        if (!mounted) return;
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
          _selectedFileType = MessageType.text;
        });
      }

      // Send text message if there's content
      if (_messageController.text.isNotEmpty) {
        await _firestore.collection('messages').add({
          ...messageData,
          'content': _messageController.text,
          'type': 'text',
        });

        if (!mounted) return;
        _messageController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Upload file to Firebase Storage
  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return null;
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${currentUser.uid}_${widget.doctorId}_$timestamp';
      final extension = _selectedFileName?.split('.').last ?? '';
      final storageRef = _storage.ref().child(
        'messages/${_getMessageTypeAsString(_selectedFileType)}s/$filename.$extension',
      );

      final uploadTask = storageRef.putFile(_selectedFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _selectedFileBytes = null;
        _selectedFileName = image.name;
        _selectedFileType = MessageType.image;
      });
    }
  }

  // Pick a PDF file
  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (!mounted) return;
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      final path = result.files.first.path!;
      setState(() {
        _selectedFile = File(path);
        _selectedFileBytes = null;
        _selectedFileName = result.files.first.name;
        _selectedFileType = MessageType.pdf;
      });
    }
  }

  // Cancel the file selection
  void _cancelFileSelection() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileType = MessageType.text;
    });
  }

  Future<void> _showImageDialog(String url) async {
    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Future<void> _showPDFDialog(String url) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SfPdfViewer.network(
                url,
                canShowPaginationDialog: true,
                canShowScrollHead: true,
                enableDoubleTapZooming: true,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online', // This could be dynamic based on doctor's status
                  style: GoogleFonts.poppins(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.primary),
            onPressed: () {
              // Handle call functionality
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Messages list with StreamBuilder
                  Expanded(
                    child:
                        messages.isEmpty
                            ? Center(
                              child: Text(
                                'No messages yet. Start the conversation!',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(
                                AppSizes.defaultPadding,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId == currentUserId;

                                return FadeInUp(
                                  from: 10,
                                  delay: Duration(milliseconds: index * 50),
                                  child: _buildMessageBubble(message, isMe),
                                );
                              },
                            ),
                  ),

                  // Selected file indicator
                  if (_selectedFile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.defaultPadding,
                        vertical: 8,
                      ),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Icon(
                            _selectedFileType == MessageType.image
                                ? Icons.image
                                : Icons.insert_drive_file,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'File selected',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelFileSelection,
                            color: AppColors.error,
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),

                  // Message input area
                  Container(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Attachment options
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: AppColors.primary,
                          ),
                          onPressed:
                              _isUploading
                                  ? null
                                  : () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder:
                                          (context) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.image,
                                                  color: AppColors.primary,
                                                ),
                                                title: Text(
                                                  'Image',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _pickImage();
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.picture_as_pdf,
                                                  color: AppColors.primary,
                                                ),
                                                title: Text(
                                                  'PDF',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _pickPDF();
                                                },
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                        ),

                        // Text input field
                        Expanded(
                          child: CustomTextField(
                            hintText: 'Type a message...',
                            controller: _messageController,
                            maxLines: 3,
                            enabled: !_isUploading,
                          ),
                        ),

                        // Send button
                        _isUploading
                            ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: AppColors.primary,
                              ),
                              onPressed: _sendMessage,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the appropriate content based on message type
            _buildMessageContent(message, isMe),

            // Display timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    if (message.type == MessageType.text) {
      return Text(
        message.content,
        style: GoogleFonts.poppins(
          color: isMe ? Colors.white : AppColors.textPrimary,
        ),
      );
    } else if (message.type == MessageType.image) {
      return GestureDetector(
        onTap: () => _showImageDialog(message.content),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.content,
            fit: BoxFit.cover,
            height: 150,
            width: 150,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                  color: AppColors.primary,
                ),
              );
            },
            errorBuilder:
                (ctx, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
          ),
        ),
      );
    } else if (message.type == MessageType.pdf) {
      return GestureDetector(
        onTap: () => _showPDFDialog(message.content),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: isMe ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.fileName ?? 'PDF File',
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time); // Today: 3:45 PM
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(time)}'; // Yesterday, 3:45 PM
    } else {
      return DateFormat('MMM d, h:mm a').format(time); // May 8, 3:45 PM
    }
  }
}
