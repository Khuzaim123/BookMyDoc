// File: lib/screens/doctor_appointments_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmydoc2/screens/appointment_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  AppointmentStatus _selectedStatus = AppointmentStatus.booked;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Appointment> appointments = [];
  Map<String, Patient> patients = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      try {
        final query =
            await _firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: user.uid)
                .where('status', isEqualTo: _selectedStatus.name)
                .orderBy('dateTime', descending: false)
                .get();
        appointments =
            query.docs.map((doc) {
              final data = doc.data();
              return Appointment(
                id: doc.id,
                patientId: data['patientId'],
                doctorId: data['doctorId'],
                dateTime: (data['dateTime'] as Timestamp).toDate(),
                status: AppointmentStatus.values.firstWhere(
                  (e) => e.toString() == 'AppointmentStatus.${data['status']}',
                  orElse: () => AppointmentStatus.booked,
                ),
                fee: (data['fee'] ?? 0.0).toDouble(),
                isPaid: data['isPaid'] ?? false,
              );
            }).toList();
      } catch (e) {
        // If the error is a Firestore index error, fallback to query without orderBy
        if (e.toString().contains('failed-precondition')) {
          final query =
              await _firestore
                  .collection('appointments')
                  .where('doctorId', isEqualTo: user.uid)
                  .where('status', isEqualTo: _selectedStatus.name)
                  .get();
          appointments =
              query.docs.map((doc) {
                final data = doc.data();
                return Appointment(
                  id: doc.id,
                  patientId: data['patientId'],
                  doctorId: data['doctorId'],
                  dateTime: (data['dateTime'] as Timestamp).toDate(),
                  status: AppointmentStatus.values.firstWhere(
                    (e) =>
                        e.toString() == 'AppointmentStatus.${data['status']}',
                    orElse: () => AppointmentStatus.booked,
                  ),
                  fee: (data['fee'] ?? 0.0).toDouble(),
                  isPaid: data['isPaid'] ?? false,
                );
              }).toList();
          setState(() {
            _isLoading = false;
            _error =
                'Some features may be limited. Please ask the admin to create the required Firestore index for best performance.';
          });
          return;
        } else {
          rethrow;
        }
      }
      // Fetch patient details
      patients = {};
      for (final appt in appointments) {
        if (!patients.containsKey(appt.patientId)) {
          final pdoc =
              await _firestore.collection('patients').doc(appt.patientId).get();
          if (pdoc.exists) {
            final pdata = pdoc.data()!;
            patients[appt.patientId] = Patient(
              id: appt.patientId,
              name: pdata['name'] ?? '',
              email: pdata['email'] ?? '',
              phone: pdata['phone'] ?? '',
            );
          } else {
            patients[appt.patientId] = Patient(
              id: appt.patientId,
              name: 'Unknown',
              email: '',
              phone: '',
            );
          }
        }
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

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointment.id).update({
        'status': newStatus.name,
      });
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as ${newStatus.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating appointment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Row(
              children: [
                _buildStatusFilter('Booked', AppointmentStatus.booked),
                const SizedBox(width: 10),
                _buildStatusFilter('Completed', AppointmentStatus.completed),
                const SizedBox(width: 10),
                _buildStatusFilter('Canceled', AppointmentStatus.canceled),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(color: AppColors.error),
                      ),
                    )
                    : appointments.isEmpty
                    ? Center(
                      child: FadeInUp(
                        child: Text(
                          'No ${_selectedStatus.toString().split('.').last} appointments',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        final patient =
                            patients[appointment.patientId] ??
                            Patient(
                              id: '',
                              name: 'Unknown',
                              email: '',
                              phone: '',
                            );
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AppointmentDetailScreen(
                                        appointment: appointment,
                                        isDoctor: true, // Doctor view
                                      ),
                                ),
                              );
                            },
                            child: CustomCard(
                              child: ListTile(
                                title: Text(
                                  patient.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                trailing:
                                    appointment.status ==
                                            AppointmentStatus.booked
                                        ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Edit button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: AppColors.primary,
                                              ),
                                              onPressed: () async {
                                                final updatedAppointment =
                                                    await Navigator.pushNamed(
                                                      context,
                                                      RouteNames
                                                          .editAppointment,
                                                      arguments: {
                                                        'appointment':
                                                            appointment,
                                                      },
                                                    );
                                                if (updatedAppointment !=
                                                    null) {
                                                  _fetchAppointments();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Appointment updated successfully',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            // Complete button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              onPressed:
                                                  () =>
                                                      _updateAppointmentStatus(
                                                        appointment,
                                                        AppointmentStatus
                                                            .completed,
                                                      ),
                                            ),
                                            // Cancel button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColors.error,
                                              ),
                                              onPressed:
                                                  () =>
                                                      _updateAppointmentStatus(
                                                        appointment,
                                                        AppointmentStatus
                                                            .canceled,
                                                      ),
                                            ),
                                          ],
                                        )
                                        : null,
                              ),
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

  // Build filter chip for appointment status
  Widget _buildStatusFilter(String label, AppointmentStatus status) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
          _fetchAppointments();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
