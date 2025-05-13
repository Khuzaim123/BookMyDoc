import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/health_record.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorPatientRecordsScreen extends StatelessWidget {
   DoctorPatientRecordsScreen({super.key});

  // Dummy data
  final List<Patient> patients = [
    Patient(id: 'patient1', name: 'Alice Johnson', email: 'alice@example.com', phone: '+1234567890'),
    Patient(id: 'patient2', name: 'Bob Smith', email: 'bob@example.com', phone: '+1234567891'),
  ];

  final List<HealthRecord> healthRecords = [
    HealthRecord(
      id: 'rec1',
      patientId: 'patient1',
      fileUrl: 'https://example.com/lab_report.pdf',
      category: 'Lab Reports',
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      sharedWith: ['doc1'],
    ),
    HealthRecord(
      id: 'rec2',
      patientId: 'patient2',
      fileUrl: 'https://example.com/prescription.pdf',
      category: 'Prescriptions',
      uploadedAt: DateTime.now().subtract(const Duration(days: 10)),
      sharedWith: ['doc1'],
    ),
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
        title: Text(
          'Patient Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: healthRecords.isEmpty
          ? Center(
        child: FadeInUp(
          child: Text(
            'No shared records available',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        itemCount: healthRecords.length,
        itemBuilder: (context, index) {
          final record = healthRecords[index];
          final patient = patients.firstWhere(
                (p) => p.id == record.patientId,
            orElse: () => Patient(id: '', name: 'Unknown', email: '', phone: ''),
          );
          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: CustomCard(
              child: ListTile(
                leading: Icon(
                  record.category == 'Lab Reports'
                      ? Icons.description
                      : Icons.medical_services,
                  color: AppColors.primary,
                ),
                title: Text(
                  '${record.category} - ${patient.name}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Uploaded: ${record.uploadedAt.toString().substring(0, 10)}',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading record...')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Viewing record...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request access to more records coming soon!')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}