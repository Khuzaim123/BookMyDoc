import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/health_record.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthRecordsScreen extends StatelessWidget {
   HealthRecordsScreen({super.key});

  // Dummy health records
  final List<HealthRecord> healthRecords = [
    HealthRecord(
      id: 'rec1',
      patientId: 'patient1',
      fileUrl: 'dummy_url.pdf',
      category: 'Lab Reports',
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    HealthRecord(
      id: 'rec2',
      patientId: 'patient1',
      fileUrl: 'dummy_url2.pdf',
      category: 'Prescriptions',
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
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
        title: Text('Health Records', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: healthRecords.isEmpty
            ? Center(
          child: Text(
            'No health records yet',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        )
            : ListView.builder(
          itemCount: healthRecords.length,
          itemBuilder: (context, index) {
            final record = healthRecords[index];
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              child: CustomCard(
                child: ListTile(
                  title: Text(
                    record.category,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Uploaded: ${record.uploadedAt.toString().substring(0, 10)}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download feature coming soon!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share feature coming soon!')),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload feature coming soon!')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}