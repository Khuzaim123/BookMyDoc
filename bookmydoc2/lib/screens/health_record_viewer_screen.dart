import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_record.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import 'package:flutter/foundation.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';

class HealthRecordViewerScreen extends StatefulWidget {
  final HealthRecord record;
  final bool isDoctor;

  const HealthRecordViewerScreen({
    super.key,
    required this.record,
    required this.isDoctor,
  });

  @override
  State<HealthRecordViewerScreen> createState() =>
      _HealthRecordViewerScreenState();
}

class _HealthRecordViewerScreenState extends State<HealthRecordViewerScreen> {
  bool _isLoading = true;
  String? _error;
  String? _patientName;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadRecordDetails();
  }

  Future<void> _loadRecordDetails() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userDoc =
          await FirebaseFirestore.instance
              .collection(widget.isDoctor ? 'patients' : 'doctors')
              .doc(widget.record.patientId)
              .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            if (widget.isDoctor) {
              _patientName = data['name'] as String? ?? 'Unknown Patient';
            } else {
              _doctorName = data['name'] as String? ?? 'Unknown Doctor';
            }
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openFile() async {
    if (!mounted) return;

    try {
      if (widget.record.fileUrl.isEmpty) {
        throw Exception('File URL is empty');
      }

      final url = Uri.parse(widget.record.fileUrl);
      if (!url.hasScheme || !url.hasAuthority) {
        throw Exception('Invalid file URL');
      }

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open file');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showFileDialog() async {
    final url = widget.record.fileUrl;
    final fileName = (widget.record as dynamic).fileName ?? url;
    debugPrint('Attempting to open file: $url (fileName: $fileName)');
    if (fileName.toLowerCase().endsWith('.pdf')) {
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
    } else if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png')) {
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
    } else {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Unsupported File'),
              content: const Text(
                'This file type cannot be opened in the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record.category,
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(color: AppColors.error),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Record details card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Details',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Category',
                              widget.record.category,
                              Icons.category,
                            ),
                            const Divider(),
                            _buildDetailRow(
                              'Upload Date',
                              '${widget.record.uploadedAt.day}/${widget.record.uploadedAt.month}/${widget.record.uploadedAt.year}',
                              Icons.calendar_today,
                            ),
                            const Divider(),
                            _buildDetailRow(
                              widget.isDoctor ? 'Patient' : 'Doctor',
                              widget.isDoctor
                                  ? _patientName ?? 'Unknown'
                                  : _doctorName ?? 'Unknown',
                              Icons.person,
                            ),
                            const Divider(),
                            _buildDetailRow(
                              'Shared With',
                              widget.record.sharedWith.isEmpty
                                  ? 'Not shared with any doctors'
                                  : '${widget.record.sharedWith.length} doctors',
                              Icons.people,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // View file button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showFileDialog,
                        icon: const Icon(Icons.visibility),
                        label: Text(
                          'View File',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
