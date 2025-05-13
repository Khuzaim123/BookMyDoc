// File: lib/screens/appointments_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmydoc2/screens/appointment_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsScreen extends StatefulWidget {
  AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  Map<String, String> _doctorNames = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final appointmentsSnapshot =
          await _firestore
              .collection('appointments')
              .where('patientId', isEqualTo: user.uid)
              .orderBy('dateTime', descending: true)
              .get();

      final appointments =
          appointmentsSnapshot.docs.map((doc) {
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

      // Fetch doctor names
      final doctorIds = appointments.map((a) => a.doctorId).toSet();
      for (final doctorId in doctorIds) {
        final doctorDoc =
            await _firestore.collection('doctors').doc(doctorId).get();
        if (doctorDoc.exists) {
          _doctorNames[doctorId] =
              doctorDoc.data()?['name'] ?? 'Unknown Doctor';
        }
      }

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      await _firestore.collection('appointments').doc(appointment.id).update({
        'status': 'canceled',
      });

      // Update the availability slot
      final slotQuery =
          await _firestore
              .collection('doctor_availabilities')
              .where('doctorId', isEqualTo: appointment.doctorId)
              .where('startTime', isEqualTo: appointment.dateTime)
              .get();

      if (slotQuery.docs.isNotEmpty) {
        await _firestore
            .collection('doctor_availabilities')
            .doc(slotQuery.docs.first.id)
            .update({'isBooked': false});
      }

      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment canceled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pushNamed(context, RouteNames.home),
        ),
        title: Text(
          'My Appointments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child:
                    _appointments.isEmpty
                        ? Center(
                          child: Text(
                            'No appointments found',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appt = _appointments[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AppointmentDetailScreen(
                                            appointment: appt,
                                            isDoctor: false, // Patient view
                                          ),
                                    ),
                                  );
                                },
                                child: CustomCard(
                                  child: ListTile(
                                    title: Text(
                                      'Dr. ${_doctorNames[appt.doctorId] ?? 'Unknown'}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${appt.dateTime.toString().substring(0, 16)} • ${appt.status.name}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (appt.status ==
                                            AppointmentStatus.booked) ...[
                                          // Edit Button
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () async {
                                              final updatedAppointment =
                                                  await Navigator.pushNamed(
                                                    context,
                                                    RouteNames.editAppointment,
                                                    arguments: {
                                                      'appointment': appt,
                                                    },
                                                  );

                                              if (updatedAppointment != null) {
                                                await _loadAppointments();
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
                                          // Cancel Button
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: AppColors.error,
                                            ),
                                            onPressed:
                                                () => _cancelAppointment(appt),
                                          ),
                                        ],
                                      ],
                                    ),
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
