import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  AppointmentStatus _selectedStatus = AppointmentStatus.booked;

  // Dummy data
  final List<Appointment> appointments = [
    Appointment(
      id: 'app1',
      patientId: 'patient1',
      doctorId: 'doc1',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      status: AppointmentStatus.booked,
      fee: 100.0,
      isPaid: true,
    ),
    Appointment(
      id: 'app2',
      patientId: 'patient2',
      doctorId: 'doc1',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      status: AppointmentStatus.completed,
      fee: 120.0,
      isPaid: true,
    ),
    Appointment(
      id: 'app3',
      patientId: 'patient3',
      doctorId: 'doc1',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      status: AppointmentStatus.canceled,
      fee: 80.0,
      isPaid: false,
    ),
  ];

  final List<Patient> patients = [
    Patient(id: 'patient1', name: 'Alice Johnson', email: 'alice@example.com', phone: '+1234567890'),
    Patient(id: 'patient2', name: 'Bob Smith', email: 'bob@example.com', phone: '+1234567891'),
    Patient(id: 'patient3', name: 'Charlie Brown', email: 'charlie@example.com', phone: '+1234567892'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = appointments.where((app) => app.status == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Appointments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: AppointmentStatus.values.map((status) {
                return FadeInDown(
                  delay: Duration(milliseconds: 100 * status.index),
                  child: ChoiceChip(
                    label: Text(
                      status.toString().split('.').last.capitalize(),
                      style: GoogleFonts.poppins(
                        color: _selectedStatus == status ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _selectedStatus == status,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.defaultPadding),

          // Appointments List
          Expanded(
            child: filteredAppointments.isEmpty
                ? Center(
              child: FadeInUp(
                child: Text(
                  'No ${_selectedStatus.toString().split('.').last} appointments',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final appointment = filteredAppointments[index];
                final patient = patients.firstWhere(
                      (p) => p.id == appointment.patientId,
                  orElse: () => Patient(id: '', name: 'Unknown', email: '', phone: ''),
                );
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: CustomCard(
                    child: ListTile(
                      title: Text(
                        patient.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time: ${appointment.dateTime.toString().substring(0, 16)}',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            'Fee: \$${appointment.fee.toStringAsFixed(2)} (${appointment.isPaid ? 'Paid' : 'Unpaid'})',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      trailing: appointment.status == AppointmentStatus.booked
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              setState(() {
                                appointment.status = AppointmentStatus.completed;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Appointment marked as completed')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.error),
                            onPressed: () {
                              setState(() {
                                appointment.status = AppointmentStatus.canceled;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Appointment canceled')),
                              );
                            },
                          ),
                        ],
                      )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}