import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:go_router/go_router.dart';

class DoctorHomeScreen extends StatelessWidget {
   DoctorHomeScreen({super.key});

  // Dummy data for demonstration
  final Doctor doctor = Doctor(
    id: 'doc1',
    name: 'Dr. John Smith',
    email: 'john@example.com',
    specialty: 'Cardiologist',
    qualifications: 'MD, PhD',
    clinicAddress: '123 Heart St',
    workingHours: {'Monday': '9:00-17:00'},
    commissionRate: 10.0,
  );

  final List<Appointment> upcomingAppointments = [
    Appointment(
      id: 'app1',
      patientId: 'patient1',
      doctorId: 'doc1',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      status: AppointmentStatus.booked,
      fee: 100.0,
      isPaid: true,
    ),
  ];

  final List<Patient> patients = [
    Patient(
      id: 'patient1',
      name: 'Patient Name',
      email: 'patient@example.com',
      phone: '+1234567890',
    ),
  ];

  final List<Message> recentMessages = [
    Message(
      id: 'msg1',
      senderId: 'patient1',
      receiverId: 'doc1',
      content: 'Hello, I have a question about my appointment.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
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
          AppStrings.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context ,RouteNames.doctorProfile), // Correct route for Doctor's own profile
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamed(context , RouteNames.login),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            FadeInDown(
              child: Text(
                'Hello, ${doctor.name}!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.smallPadding),

            // Quick Actions (Updated to include all Doctor screens)
            FadeInUp(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(context, 'Appointments', Icons.calendar_today),
                      _buildActionButton(context, 'Messages', Icons.message),
                      _buildActionButton(context, 'Availability', Icons.schedule),
                    ],
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(context, 'Earnings', Icons.account_balance_wallet),
                      _buildActionButton(context, 'Records', Icons.medical_services),
                      _buildActionButton(context, 'Profile', Icons.person),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Upcoming Appointments
            FadeInLeft(
              child: Text(
                'Upcoming Appointments',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            upcomingAppointments.isEmpty
                ? FadeInUp(
              child: Center(
                child: Text(
                  'No upcoming appointments',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : Column(
              children: upcomingAppointments.map((appointment) {
                final patient = patients.firstWhere(
                      (p) => p.id == appointment.patientId,
                  orElse: () => Patient(id: '', name: 'Unknown', email: '', phone: ''),
                );
                return FadeInRight(
                  child: CustomCard(
                    child: ListTile(
                      title: Text(
                        'Patient: ${patient.name}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Time: ${appointment.dateTime.toString().substring(0, 16)}',
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                      ),
                      onTap: () {
                        // Navigate to appointment details (to be implemented)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appointment details coming soon!')),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Recent Messages
            FadeInLeft(
              child: Text(
                'Recent Messages',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            recentMessages.isEmpty
                ? FadeInUp(
              child: Center(
                child: Text(
                  'No recent messages',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : Column(
              children: recentMessages.map((message) {
                final patient = patients.firstWhere(
                      (p) => p.id == message.senderId,
                  orElse: () => Patient(id: '', name: 'Unknown', email: '', phone: ''),
                );
                return FadeInRight(
                  child: CustomCard(
                    child: ListTile(
                      title: Text(
                        patient.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        message.content,
                        style: GoogleFonts.poppins(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: message.isRead
                          ? null
                          : const Icon(
                        Icons.circle,
                        color: AppColors.primary,
                        size: 10,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context , '${RouteNames.message}?id=${message.senderId}');
                      },
                    ),
                  ),
                );
              }).toList(),
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
                if (label == 'Appointments') {
                  Navigator.pushNamed(context, RouteNames.doctorAppointments);
                } else if (label == 'Messages') {
                  Navigator.pushNamed(context, RouteNames.doctorMessagesList);
                } else if (label == 'Availability') {
                  Navigator.pushNamed(context, RouteNames.doctorAvailability);
                } else if (label == 'Earnings') {
                  Navigator.pushNamed(context, RouteNames.doctorEarnings);
                } else if (label == 'Records') {
                  Navigator.pushNamed(context, RouteNames.doctorPatientRecords);
                } else if (label == 'Profile') {
                  Navigator.pushNamed(context, RouteNames.doctorProfile);
                }
              },

           style: ElevatedButton.styleFrom(
             backgroundColor: AppColors.primary.withOpacity(0.1),
             foregroundColor: AppColors.primary,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
             ),
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(icon, size: AppSizes.largeIcon),
               const SizedBox(height: AppSizes.smallPadding),
               Text(
                 label,
                 style: GoogleFonts.poppins(fontSize: 12),
                 textAlign: TextAlign.center,
               ),
             ],
           ),
         ),
       ),
     );
   }
}