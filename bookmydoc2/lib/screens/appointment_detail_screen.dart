// lib/screens/appointment_detail_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment? appointment;
  final String? appointmentId;
  final bool isDoctor; // To determine if doctor or patient is viewing

  const AppointmentDetailScreen({
    super.key,
    this.appointment,
    this.appointmentId,
    required this.isDoctor,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  Appointment? appointment;
  bool _isLoading = true;
  Doctor? _doctor;
  Patient? _patient;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _fetchAppointmentAndDetails(widget.appointmentId!);
    } else if (widget.appointment != null) {
      appointment = widget.appointment;
      _loadDetails();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'No appointment data provided.';
      });
    }
  }

  Future<void> _fetchAppointmentAndDetails(String appointmentId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _error = 'Appointment not found.';
        });
        return;
      }
      final data = doc.data()!;
      appointment = Appointment(
        id: doc.id,
        patientId: data['patientId'],
        doctorId: data['doctorId'],
        dateTime: (data['startTime'] as Timestamp).toDate(),
        status: AppointmentStatus.values.firstWhere(
          (e) => e.toString() == 'AppointmentStatus.${data['status']}',
          orElse: () => AppointmentStatus.booked,
        ),
        fee: (data['fee'] ?? 0.0).toDouble(),
        isPaid: data['isPaid'] ?? false,
        notes: data['notes'],
      );
      await _loadDetails();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading appointment: $e';
      });
    }
  }

  Future<void> _loadDetails() async {
    if (appointment == null) {
      setState(() {
        _isLoading = false;
        _error = 'No appointment data.';
      });
      return;
    }
    try {
      // Load doctor details
      final doctorDoc =
          await _firestore
              .collection('doctors')
              .doc(appointment!.doctorId)
              .get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data()!;
        _doctor = Doctor(
          id: doctorDoc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          specialty: data['specialty'] ?? '',
          qualifications: data['qualifications'] ?? '',
          clinicAddress: data['clinicAddress'] ?? '',
          workingHours: Map<String, String>.from(data['workingHours'] ?? {}),
          rating: (data['rating'] ?? 0.0).toDouble(),
          experience: data['experience'] ?? 0,
          consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
        );
      }

      // Load patient details
      final patientDoc =
          await _firestore
              .collection('patients')
              .doc(appointment!.patientId)
              .get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        _patient = Patient(
          id: patientDoc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context, appointment),
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
              : appointment == null
              ? Center(
                child: Text(
                  'No appointment data.',
                  style: GoogleFonts.poppins(color: AppColors.error),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status banner
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _buildStatusBanner(),
                    ),

                    const SizedBox(height: 20),

                    // Person Details (Doctor or Patient)
                    if (_doctor != null && _patient != null)
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isDoctor
                                      ? 'Patient Details'
                                      : 'Doctor Details',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPersonDetail(
                                  icon: Icons.person,
                                  title: 'Name',
                                  value:
                                      widget.isDoctor
                                          ? _patient!.name
                                          : _doctor!.name,
                                ),
                                const Divider(),
                                _buildPersonDetail(
                                  icon: Icons.email,
                                  title: 'Email',
                                  value:
                                      widget.isDoctor
                                          ? _patient!.email
                                          : _doctor!.email,
                                ),
                                const Divider(),
                                if (widget.isDoctor)
                                  _buildPersonDetail(
                                    icon: Icons.phone,
                                    title: 'Phone',
                                    value: _patient!.phone,
                                  ),
                                if (!widget.isDoctor)
                                  _buildPersonDetail(
                                    icon: Icons.medical_services,
                                    title: 'Specialty',
                                    value: _doctor!.specialty,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Appointment Details
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: CustomCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Details',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAppointmentDetail(
                                icon: Icons.calendar_today,
                                title: 'Date',
                                value: DateFormat(
                                  'EEEE, MMM d, yyyy',
                                ).format(appointment!.dateTime),
                              ),
                              const Divider(),
                              _buildAppointmentDetail(
                                icon: Icons.access_time,
                                title: 'Time',
                                value: DateFormat(
                                  'h:mm a',
                                ).format(appointment!.dateTime),
                              ),
                              const Divider(),
                              _buildAppointmentDetail(
                                icon: Icons.attach_money,
                                title: 'Fee',
                                value:
                                    '\$${appointment!.fee.toStringAsFixed(2)} (${appointment!.isPaid ? 'Paid' : 'Unpaid'})',
                              ),

                              // Notes section if available
                              if (appointment!.notes != null &&
                                  appointment!.notes!.isNotEmpty) ...[
                                const Divider(),
                                _buildAppointmentDetail(
                                  icon: Icons.note,
                                  title: 'Notes',
                                  value: appointment!.notes!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusBanner() {
    Color statusColor;
    switch (appointment!.status) {
      case AppointmentStatus.booked:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.canceled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor),
          const SizedBox(width: 8),
          Text(
            'Status: ${appointment!.status.name.toUpperCase()}',
            style: GoogleFonts.poppins(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
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

  Widget _buildAppointmentDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
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
