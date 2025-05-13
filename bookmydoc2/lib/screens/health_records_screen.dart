import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../models/health_record.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../screens/health_record_viewer_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For file upload
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  // List of available record categories
  final List<String> _recordCategories = [
    'Lab Reports',
    'Prescriptions',
    'Imaging Reports',
    'Vaccination Records',
    'Medical History',
    'Other',
  ];

  // Function to pick file
  Future<void> _pickFile() async {
    if (!mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        if (path != null) {
          setState(() {
            _selectedFile = File(path);
            _selectedFileName = file.name;
          });

          _showCategorySelectionDialog();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show category selection dialog
  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Record Category'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _recordCategories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_recordCategories[index]),
                    onTap: () {
                      Navigator.pop(context, _recordCategories[index]);
                    },
                  );
                },
              ),
            ),
          ),
    ).then((selectedCategory) {
      if (selectedCategory != null && _selectedFile != null) {
        _uploadHealthRecord(selectedCategory);
      }
    });
  }

  // Function to upload health record
  Future<void> _uploadHealthRecord(String category) async {
    if (!mounted) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (_selectedFileName == null) {
        throw Exception('File name is missing');
      }

      final storageRef = _storage
          .ref()
          .child('health_records')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName');

      final uploadTask = storageRef.putFile(_selectedFile!);
      final taskSnapshot = await uploadTask;
      final fileUrl = await taskSnapshot.ref.getDownloadURL();

      final docRef = _firestore.collection('health_records').doc();
      final healthRecord = HealthRecord(
        id: docRef.id,
        patientId: user.uid,
        fileUrl: fileUrl,
        category: category,
        uploadedAt: DateTime.now(),
        fileName: _selectedFileName,
      );

      await docRef.set(healthRecord.toJson());

      if (!mounted) return;

      setState(() {
        _selectedFile = null;
        _selectedFileName = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health record uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading record: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to share record with doctor
  Future<void> _shareWithDoctor(String recordId, String doctorId) async {
    try {
      await _firestore.collection('health_records').doc(recordId).update({
        'sharedWith': FieldValue.arrayUnion([doctorId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record shared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing record: ${e.toString()}')),
        );
      }
    }
  }

  // Function to delete health record
  Future<void> _deleteHealthRecord(HealthRecord record) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Record'),
              content: const Text(
                'Are you sure you want to delete this health record? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (shouldDelete != true) return;

      // Delete file from Storage
      final fileRef = _storage.refFromURL(record.fileUrl);
      await fileRef.delete();

      // Delete document from Firestore
      await _firestore.collection('health_records').doc(record.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting record: ${e.toString()}')),
        );
      }
    }
  }

  // Function to edit health record
  Future<void> _editHealthRecord(HealthRecord record) async {
    String? selectedCategory = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Record Category'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _recordCategories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_recordCategories[index]),
                    selected: _recordCategories[index] == record.category,
                    onTap: () {
                      Navigator.pop(context, _recordCategories[index]);
                    },
                  );
                },
              ),
            ),
          ),
    );

    if (selectedCategory != null && selectedCategory != record.category) {
      try {
        await _firestore.collection('health_records').doc(record.id).update({
          'category': selectedCategory,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record category updated successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating record: ${e.toString()}')),
          );
        }
      }
    }
  }

  // Function to view health record details
  void _showRecordDetails(HealthRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              record.category,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Upload Date'),
                          subtitle: Text(
                            '${record.uploadedAt.day}/${record.uploadedAt.month}/${record.uploadedAt.year}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Shared With'),
                          subtitle: Text(
                            record.sharedWith.isEmpty
                                ? 'Not shared with any doctors'
                                : '${record.sharedWith.length} doctors',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse(record.fileUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not open file'),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('View File'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _editHealthRecord(record),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _deleteHealthRecord(record),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _onRecordTap(HealthRecord record) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HealthRecordViewerScreen(record: record, isDoctor: false),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening record: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRecordItem(HealthRecord record) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onRecordTap(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(record.category),
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.category,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uploaded on ${_formatDate(record.uploadedAt)}',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Lab Reports':
        return Icons.science;
      case 'Prescriptions':
        return Icons.medication;
      case 'Imaging Reports':
        return Icons.image;
      case 'Vaccination Records':
        return Icons.vaccines;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view health records')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Health Records'), elevation: 0),
      body:
          _isUploading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Uploading health record...'),
                  ],
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('health_records')
                        .where('patientId', isEqualTo: user.uid)
                        .orderBy('uploadedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final records = snapshot.data?.docs ?? [];

                  if (records.isEmpty) {
                    return const Center(child: Text('No health records found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = HealthRecord.fromJson(
                        records[index].data() as Map<String, dynamic>,
                      );

                      return _buildRecordItem(record);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
