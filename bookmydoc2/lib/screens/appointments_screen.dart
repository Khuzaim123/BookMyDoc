import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentsScreen extends StatelessWidget {
   AppointmentsScreen({super.key});

  // Dummy appointment data
  final List<Appointment> appointments = [
    Appointment(
      id: 'appt1',
      patientId: 'patient1',
      doctorId: 'doc1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      status: AppointmentStatus.booked,
      fee: 50.0,
    ),
    Appointment(
      id: 'appt2',
      patientId: 'patient1',
      doctorId: 'doc2',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      status: AppointmentStatus.completed,
      fee: 60.0,
      isPaid: true,
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
        title: Text('My Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: appointments.isEmpty
            ? Center(
          child: Text(
            'No appointments found',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        )
            : ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              child: CustomCard(
                child: ListTile(
                  title: Text(
                    'Dr. ${appt.doctorId == 'doc1' ? 'John Smith' : 'Jane Doe'}', // Dummy name
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${appt.dateTime.toString().substring(0, 16)} • ${appt.status.name}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (appt.status == AppointmentStatus.booked) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary),
                          onPressed: () {
                            // Reschedule logic (navigate to booking screen later)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reschedule coming soon!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.error),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Appointment canceled!')),
                            );
                          },
                        ),
                      ],
                      if (appt.status == AppointmentStatus.completed)
                        IconButton(
                          icon: const Icon(Icons.star, color: AppColors.accent),
                          onPressed: () {
                            // Review logic (navigate to rating screen later)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review feature coming soon!')),
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
    );
  }
}