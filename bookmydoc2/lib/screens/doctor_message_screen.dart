import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../models/message.dart';
import '../models/patient.dart';
import '../widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';

class DoctorMessageScreen extends StatefulWidget {
  final String patientId;

  const DoctorMessageScreen({super.key, required this.patientId});

  @override
  State<DoctorMessageScreen> createState() => _DoctorMessageScreenState();
}

class _DoctorMessageScreenState extends State<DoctorMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  MessageType _selectedFileType = MessageType.text;
  String? _selectedFileUrl;
  Patient? patient;
  bool _isLoading = true;
  String? _error;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchPatient();
  }

  Future<void> _fetchPatient() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final pdoc =
          await _firestore.collection('patients').doc(widget.patientId).get();
      if (pdoc.exists) {
        final pdata = pdoc.data()!;
        patient = Patient(
          id: widget.patientId,
          name: pdata['name'] ?? '',
          email: pdata['email'] ?? '',
          phone: pdata['phone'] ?? '',
        );
      } else {
        patient = Patient(
          id: widget.patientId,
          name: 'Unknown',
          email: '',
          phone: '',
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickFile(MessageType fileType) async {
    _selectedFileType = fileType;
    FilePickerResult? result;
    if (fileType == MessageType.image) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedFileBytes = null;
          _selectedFileName = image.name;
        });
      }
    } else if (fileType == MessageType.pdf) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          setState(() {
            _selectedFile = File(path);
            _selectedFileBytes = null;
            _selectedFileName = result!.files.first.name;
          });
        }
      }
    }
  }

  void _showFileTypeSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: Text('Image', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(MessageType.image);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.primary,
                ),
                title: Text('PDF', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(MessageType.pdf);
                },
              ),
            ],
          ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String?> _uploadFileToStorage() async {
    if (_selectedFile == null) return null;
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${user.uid}_${widget.patientId}_$timestamp';
      final extension = _selectedFileName?.split('.').last ?? '';
      final storageRef = _storage.ref().child(
        'messages/${_selectedFileType == MessageType.image ? 'images' : 'pdfs'}/$filename.$extension',
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

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_messageController.text.isEmpty && _selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final messageData = {
        'senderId': user.uid,
        'receiverId': widget.patientId,
        'participants': [user.uid, widget.patientId],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      if (_selectedFile != null) {
        final fileUrl = await _uploadFileToStorage();
        if (fileUrl != null) {
          await _firestore.collection('messages').add({
            ...messageData,
            'content': fileUrl,
            'type': _selectedFileType == MessageType.image ? 'image' : 'pdf',
            'fileName': _selectedFileName,
          });
        }
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
          _selectedFileType = MessageType.text;
        });
      }

      if (_messageController.text.isNotEmpty) {
        await _firestore.collection('messages').add({
          ...messageData,
          'content': _messageController.text,
          'type': 'text',
        });
        _messageController.clear();
      }

      await _fetchPatient();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
    PDFDocument? document;
    bool loading = true;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (loading) {
              PDFDocument.fromURL(url)
                  .then((doc) {
                    setState(() {
                      document = doc;
                      loading = false;
                    });
                  })
                  .catchError((e) {
                    setState(() {
                      error = e.toString();
                      loading = false;
                    });
                  });
            }
            return Dialog(
              backgroundColor: Colors.black,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child:
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                        ? Center(
                          child: Text(
                            'Failed to load PDF',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                        : PDFViewer(document: document!),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isFromDoctor) {
    return Align(
      alignment: isFromDoctor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromDoctor ? AppColors.primary : Colors.white,
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
            _buildMessageContent(message, isFromDoctor),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.poppins(
                  color: isFromDoctor ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isFromDoctor) {
    if (message.type == MessageType.text) {
      return Text(
        message.content,
        style: GoogleFonts.poppins(
          color: isFromDoctor ? Colors.white : AppColors.textPrimary,
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
              color: isFromDoctor ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.fileName ?? 'PDF File',
                style: GoogleFonts.poppins(
                  color: isFromDoctor ? Colors.white : AppColors.textPrimary,
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
      return DateFormat('h:mm a').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(time)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
                  patient?.name ?? 'Patient',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online',
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('messages')
                        .where('participants', arrayContains: user?.uid)
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final messages =
                      docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            if ((data['senderId'] == user?.uid &&
                                    data['receiverId'] == widget.patientId) ||
                                (data['senderId'] == widget.patientId &&
                                    data['receiverId'] == user?.uid)) {
                              DateTime timestamp;
                              if (data['timestamp'] == null) {
                                timestamp = DateTime.now();
                              } else if (data['timestamp'] is Timestamp) {
                                timestamp =
                                    (data['timestamp'] as Timestamp).toDate();
                              } else {
                                timestamp = DateTime.now();
                              }

                              return Message(
                                id: doc.id,
                                senderId: data['senderId'],
                                receiverId: data['receiverId'],
                                content: data['content'],
                                timestamp: timestamp,
                                isRead: data['isRead'] ?? false,
                                type:
                                    data['type'] == 'image'
                                        ? MessageType.image
                                        : data['type'] == 'pdf'
                                        ? MessageType.pdf
                                        : MessageType.text,
                                fileName: data['fileName'],
                              );
                            }
                            return null;
                          })
                          .whereType<Message>()
                          .toList();

                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  return Column(
                    children: [
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
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(
                                    AppSizes.defaultPadding,
                                  ),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isFromDoctor =
                                        user != null &&
                                        message.senderId == user.uid;
                                    return FadeInUp(
                                      from: 10,
                                      delay: Duration(milliseconds: index * 50),
                                      child: _buildMessageBubble(
                                        message,
                                        isFromDoctor,
                                      ),
                                    );
                                  },
                                ),
                      ),
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
                                onPressed:
                                    () => setState(() {
                                      _selectedFile = null;
                                      _selectedFileName = null;
                                      _selectedFileType = MessageType.text;
                                    }),
                                color: AppColors.error,
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
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
                            IconButton(
                              icon: const Icon(
                                Icons.attach_file,
                                color: AppColors.primary,
                              ),
                              onPressed:
                                  _isUploading
                                      ? null
                                      : _showFileTypeSelectionDialog,
                            ),
                            Expanded(
                              child: CustomTextField(
                                hintText: 'Type a message...',
                                controller: _messageController,
                                maxLines: 3,
                                enabled: !_isUploading,
                              ),
                            ),
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
                  );
                },
              ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
