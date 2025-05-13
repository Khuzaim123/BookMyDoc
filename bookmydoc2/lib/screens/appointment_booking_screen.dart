import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/doctor_availability.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookmydoc2/models/appointment.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String doctorId;

  const AppointmentBookingScreen({super.key, required this.doctorId});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DoctorAvailability? _selectedSlot;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Doctor? _doctor;
  List<DoctorAvailability> _availability = [];
  bool _doctorLoading = true;
  bool _slotsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctor();
    _fetchAvailability();
  }

  Future<void> _fetchDoctor() async {
    setState(() => _doctorLoading = true);
    final doc =
        await _firestore.collection('doctors').doc(widget.doctorId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _doctor = Doctor(
          id: widget.doctorId,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          specialty: data['specialty'] ?? '',
          qualifications: data['qualifications'] ?? '',
          clinicAddress: data['clinicAddress'] ?? '',
          workingHours: Map<String, String>.from(data['workingHours'] ?? {}),
        );
        _doctorLoading = false;
      });
    }
  }

  Future<void> _fetchAvailability() async {
    setState(() => _slotsLoading = true);
    final start = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      0,
      0,
      0,
    );
    final end = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      23,
      59,
      59,
    );
    final query =
        await _firestore
            .collection('doctor_availabilities')
            .where('doctorId', isEqualTo: widget.doctorId)
            .where('startTime', isGreaterThanOrEqualTo: start)
            .where('startTime', isLessThanOrEqualTo: end)
            .where('isBooked', isEqualTo: false)
            .orderBy('startTime')
            .get();
    setState(() {
      _availability =
          query.docs.map((doc) {
            final data = doc.data();
            return DoctorAvailability(
              id: doc.id,
              doctorId: data['doctorId'],
              startTime: (data['startTime'] as Timestamp).toDate(),
              endTime: (data['endTime'] as Timestamp).toDate(),
              isBooked: data['isBooked'] ?? false,
            );
          }).toList();
      _slotsLoading = false;
    });
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create an Appointment object using the Appointment model
      final appointment = Appointment(
        id: _firestore.collection('appointments').doc().id, // Generate a new ID
        patientId: user.uid,
        doctorId: widget.doctorId,
        dateTime: _selectedSlot!.startTime,
        fee: 0.0, // Set a default fee or fetch from doctor's data
        status: AppointmentStatus.booked,
      );

      // Add the appointment to Firestore using the Appointment model's toJson method
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toJson());

      // Mark slot as booked
      await _firestore
          .collection('doctor_availabilities')
          .doc(_selectedSlot!.id)
          .update({'isBooked': true});

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment booked!')));
      Navigator.pushNamed(context, RouteNames.appointments);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
    _fetchAvailability(); // Refresh slots
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _doctor;
    final availability = _availability;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          doctor == null ? 'Book Appointment' : 'Book with ${doctor.name}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            FadeInDown(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedSlot = null; // Reset slot selection
                  });
                  _fetchAvailability();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Available Slots
            FadeInUp(
              child: Text(
                'Available Slots',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            _slotsLoading
                ? const Center(child: CircularProgressIndicator())
                : availability.isEmpty
                ? Center(
                  child: Text(
                    'No available slots for this day',
                    style: GoogleFonts.poppins(),
                  ),
                )
                : Wrap(
                  spacing: AppSizes.defaultPadding,
                  children:
                      availability.map((slot) {
                        final isSelected = _selectedSlot == slot;
                        return FadeInRight(
                          child: ChoiceChip(
                            label: Text(
                              '${slot.startTime.hour}:${slot.startTime.minute.toString().padLeft(2, '0')} - '
                              '${slot.endTime.hour}:${slot.endTime.minute.toString().padLeft(2, '0')}',
                            ),
                            selected: isSelected,
                            onSelected:
                                slot.isBooked
                                    ? null
                                    : (selected) => setState(
                                      () =>
                                          _selectedSlot =
                                              selected ? slot : null,
                                    ),
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.poppins(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                ),
            const SizedBox(height: AppSizes.largePadding),

            // Book Button
            FadeInUp(
              child: CustomButton(
                text: 'Book Appointment',
                onPressed: _bookAppointment,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
