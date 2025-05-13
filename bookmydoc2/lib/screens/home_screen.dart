import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/health_tip.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Dummy data for now (replace with Firebase fetch later)
  final List<Doctor> recommendedDoctors = [
    Doctor(
      id: 'doc1',
      name: 'Dr. John Smith',
      email: 'john@example.com',
      specialty: 'Cardiologist',
      qualifications: 'MD, PhD',
      clinicAddress: '123 Heart St',
      workingHours: {'Monday': '9:00-17:00'},
    ),
    Doctor(
      id: 'doc2',
      name: 'Dr. Jane Doe',
      email: 'jane@example.com',
      specialty: 'Dentist',
      qualifications: 'DDS',
      clinicAddress: '456 Smile Ave',
      workingHours: {'Tuesday': '10:00-18:00'},
    ),
  ];

  final List<HealthTip> healthTips = [
    HealthTip(
      id: 'tip1',
      title: 'Stay Hydrated',
      content: 'Drink 8 glasses of water daily',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>Navigator.pushNamed(context , RouteNames.search),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>Navigator.pushNamed(context , RouteNames.profileManagement),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamed(context , RouteNames.login), // Replace stack on logout
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            FadeInDown(
              child: Text(
                'Hello, Patient!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.smallPadding),

            // Quick Actions
            FadeInUp(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(context, 'Messages', Icons.message),
                  _buildActionButton(context, 'Book Appointment', Icons.calendar_today),
                  _buildActionButton(context, 'Appointments', Icons.event),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(context, 'Health Records', Icons.medical_services),
                  _buildActionButton(context, 'Profile', Icons.person),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Recommended Doctors
            FadeInLeft(
              child: Text(
                'Recommended Doctors',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            Column(
              children: recommendedDoctors.map((doctor) => FadeInRight(
                child: GestureDetector(
                  onTap: () =>Navigator.pushNamed(context , '${RouteNames.doctorProfileView}?id=${doctor.id}'),
                  child: CustomCard(
                    child: ListTile(
                      title: Text(doctor.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text(doctor.specialty, style: GoogleFonts.poppins()),
                      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Health Tips
            FadeInUp(
              child: Text(
                'Health Tips',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            Column(
              children: healthTips.map((tip) => FadeInDown(
                child: CustomCard(
                  child: ListTile(
                    title: Text(tip.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text(tip.content, style: GoogleFonts.poppins()),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.smallPadding),
        child: ElevatedButton(
          onPressed: () {
            if (label == 'Book Appointment') {
             Navigator.pushNamed(context , RouteNames.search); // Redirect to SearchScreen
            } else if (label == 'Appointments') {
             Navigator.pushNamed(context , RouteNames.appointments);
            } else if (label == 'Messages') {
             Navigator.pushNamed(context , RouteNames.messagesList);
            } else if (label == 'Health Records') {
             Navigator.pushNamed(context , RouteNames.healthRecords);
            } else if (label == 'Profile') {
             Navigator.pushNamed(context , RouteNames.profileManagement);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.largeIcon),
              const SizedBox(height: AppSizes.smallPadding),
              Text(label, style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}