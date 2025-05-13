import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../models/health_record.dart';
import '../models/patient.dart';
import '../widgets/custom_button.dart';
import '../screens/health_record_viewer_screen.dart';

class DoctorPatientRecordsScreen extends StatefulWidget {
  const DoctorPatientRecordsScreen({super.key});

  @override
  State<DoctorPatientRecordsScreen> createState() =>
      _DoctorPatientRecordsScreenState();
}

class _DoctorPatientRecordsScreenState
    extends State<DoctorPatientRecordsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Patient> patients = [];
  List<HealthRecord> healthRecords = [];
  bool _isLoading = true;
  String? _error;

  // For filtering
  String? selectedPatientId;

  // For file upload
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _selectedPatientForUpload;

  // List of available record categories
  final List<String> _recordCategories = [
    'Lab Reports',
    'Prescriptions',
    'Imaging Reports',
    'Vaccination Records',
    'Medical History',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPatientsAndRecords();
  }

  Future<void> _fetchPatientsAndRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Fetch patients
      final patientsQuery = await _firestore.collection('patients').get();
      patients =
          patientsQuery.docs.map((doc) {
            final data = doc.data();
            return Patient(
              id: doc.id,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              phone: data['phone'] ?? '',
            );
          }).toList();
      // Fetch health records shared with this doctor
      try {
        final recordsQuery =
            await _firestore
                .collection('health_records')
                .where('sharedWith', arrayContains: user.uid)
                .orderBy('uploadedAt', descending: true)
                .get();
        healthRecords =
            recordsQuery.docs.map((doc) {
              final data = doc.data();
              return HealthRecord(
                id: doc.id,
                patientId: data['patientId'],
                fileUrl: data['fileUrl'],
                category: data['category'],
                uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
                sharedWith: List<String>.from(data['sharedWith'] ?? []),
              );
            }).toList();
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        // If the error is a Firestore index error, fallback to query without orderBy
        if (e.toString().contains('failed-precondition')) {
          final recordsQuery =
              await _firestore
                  .collection('health_records')
                  .where('sharedWith', arrayContains: user.uid)
                  .get();
          healthRecords =
              recordsQuery.docs.map((doc) {
                final data = doc.data();
                return HealthRecord(
                  id: doc.id,
                  patientId: data['patientId'],
                  fileUrl: data['fileUrl'],
                  category: data['category'],
                  uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
                  sharedWith: List<String>.from(data['sharedWith'] ?? []),
                );
              }).toList();
          setState(() {
            _isLoading = false;
            _error =
                'Some features may be limited. Please ask the admin to create the required Firestore index for best performance.';
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Filtered health records based on selected patient
  List<HealthRecord> get filteredRecords {
    if (selectedPatientId == null) {
      return healthRecords;
    }
    return healthRecords
        .where((record) => record.patientId == selectedPatientId)
        .toList();
  }

  // Function to pick file
  Future<void> _pickFile() async {
    // First select patient
    await _showPatientSelectionDialog();
    if (_selectedPatientForUpload == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
          // Show category selection after file is picked
          _showCategorySelectionDialog();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }

  // Function to select patient for upload
  Future<void> _showPatientSelectionDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Select Patient',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return ListTile(
                    title: Text(patient.name),
                    subtitle: Text(patient.email),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPatientForUpload = patient.id;
                      });
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  // Function to show category selection dialog
  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Select Record Category',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
    if (_selectedFile == null || _selectedPatientForUpload == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would:
      // 1. Upload the file to Firebase Storage
      // 2. Get the download URL
      // 3. Save the record data to Firestore

      // For now, just save metadata to Firestore (simulate file upload)
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final docRef = _firestore.collection('health_records').doc();
      await docRef.set({
        'id': docRef.id,
        'patientId': _selectedPatientForUpload!,
        'fileUrl': 'https://example.com/${_selectedFileName}',
        'category': category,
        'uploadedAt': DateTime.now(),
        'sharedWith': [user.uid],
      });
      setState(() {
        _selectedFile = null;
        _selectedFileName = null;
        _selectedPatientForUpload = null;
        _isUploading = false;
      });
      await _fetchPatientsAndRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading record: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Patient Health Records',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isUploading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading health record...',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(color: AppColors.error),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient filter dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.smallPadding,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          hint: Text(
                            'Filter by Patient',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: selectedPatientId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Patients'),
                            ),
                            ...patients.map(
                              (patient) => DropdownMenuItem<String?>(
                                value: patient.id,
                                child: Text(patient.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPatientId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Health records list
                    Expanded(
                      child:
                          filteredRecords.isEmpty
                              ? Center(
                                child: Text(
                                  'No health records found',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = filteredRecords[index];
                                  final patient = patients.firstWhere(
                                    (p) => p.id == record.patientId,
                                    orElse:
                                        () => Patient(
                                          id: '',
                                          name: 'Unknown Patient',
                                          email: '',
                                          phone: '',
                                        ),
                                  );

                                  return FadeInUp(
                                    delay: Duration(milliseconds: 100 * index),
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: Icon(
                                            record.category == 'Lab Reports'
                                                ? Icons.science
                                                : record.category ==
                                                    'Prescriptions'
                                                ? Icons.medication
                                                : record.category ==
                                                    'Imaging Reports'
                                                ? Icons.image
                                                : Icons.description,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        title: Text(
                                          record.category,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Patient: ${patient.name}',
                                              style: GoogleFonts.poppins(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Uploaded: ${record.uploadedAt.day}/${record.uploadedAt.month}/${record.uploadedAt.year}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.visibility,
                                                color: AppColors.primary,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            HealthRecordViewerScreen(
                                                              record: record,
                                                              isDoctor: true,
                                                            ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      HealthRecordViewerScreen(
                                                        record: record,
                                                        isDoctor: true,
                                                      ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
