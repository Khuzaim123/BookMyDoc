// File: lib/screens/edit_appointment_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/doctor_availability.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentScreen({super.key, required this.appointment});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  DoctorAvailability? _selectedSlot;
  bool _isLoading = false;
  bool _isLoadingSlots = true;
  final _notesController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Doctor? _doctor;
  List<DoctorAvailability> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.appointment.dateTime;
    _focusedDay = widget.appointment.dateTime;
    _notesController.text = widget.appointment.notes ?? '';
    _loadDoctorAndSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorAndSlots() async {
    try {
      // Load doctor details
      final doctorDoc =
          await _firestore
              .collection('doctors')
              .doc(widget.appointment.doctorId)
              .get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data()!;
        setState(() {
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
        });
      }

      await _loadAvailableSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctor details: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
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
              .where('doctorId', isEqualTo: widget.appointment.doctorId)
              .where('startTime', isGreaterThanOrEqualTo: start)
              .where('startTime', isLessThanOrEqualTo: end)
              .where('isBooked', isEqualTo: false)
              .orderBy('startTime')
              .get();

      final slots =
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

      // Add the current appointment's slot if it's not in the list
      if (!slots.any(
        (slot) =>
            _isSameHourAndMinute(slot.startTime, widget.appointment.dateTime),
      )) {
        final currentSlot = DoctorAvailability(
          id: 'current',
          doctorId: widget.appointment.doctorId,
          startTime: widget.appointment.dateTime,
          endTime: widget.appointment.dateTime.add(const Duration(minutes: 30)),
          isBooked: true,
        );
        slots.add(currentSlot);
      }

      setState(() {
        _availableSlots = slots;
        _selectedSlot = slots.firstWhere(
          (slot) =>
              _isSameHourAndMinute(slot.startTime, widget.appointment.dateTime),
          orElse: () => slots.first,
        );
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available slots: $e')),
        );
      }
    }
  }

  bool _isSameHourAndMinute(DateTime a, DateTime b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  Future<void> _updateAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the appointment
      await _firestore
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({
            'startTime': _selectedSlot!.startTime,
            'endTime': _selectedSlot!.endTime,
            'notes': _notesController.text,
          });

      // If the slot is different from the current one, update the availability
      if (_selectedSlot!.id != 'current') {
        // Mark the old slot as available
        final oldSlotQuery =
            await _firestore
                .collection('doctor_availabilities')
                .where('doctorId', isEqualTo: widget.appointment.doctorId)
                .where('startTime', isEqualTo: widget.appointment.dateTime)
                .get();

        if (oldSlotQuery.docs.isNotEmpty) {
          await _firestore
              .collection('doctor_availabilities')
              .doc(oldSlotQuery.docs.first.id)
              .update({'isBooked': false});
        }

        // Mark the new slot as booked
        await _firestore
            .collection('doctor_availabilities')
            .doc(_selectedSlot!.id)
            .update({'isBooked': true});
      }

      // Create updated appointment object
      final updatedAppointment = Appointment(
        id: widget.appointment.id,
        patientId: widget.appointment.patientId,
        doctorId: widget.appointment.doctorId,
        dateTime: _selectedSlot!.startTime,
        status: widget.appointment.status,
        fee: widget.appointment.fee,
        isPaid: widget.appointment.isPaid,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated successfully')),
        );
        Navigator.pop(context, updatedAppointment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update appointment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Appointment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Info Card
                    if (_doctor != null)
                      FadeInDown(
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _doctor!.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        _doctor!.specialty,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Calendar
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Builder(
                        builder: (context) {
                          final DateTime today = DateTime.now();
                          final DateTime firstDay = today;
                          final DateTime lastDay = today.add(
                            const Duration(days: 30),
                          );
                          final DateTime focusedDay =
                              _focusedDay.isBefore(firstDay)
                                  ? firstDay
                                  : _focusedDay;
                          return TableCalendar(
                            firstDay: firstDay,
                            lastDay: lastDay,
                            focusedDay: focusedDay,
                            selectedDayPredicate:
                                (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, newFocusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = newFocusedDay;
                                _selectedSlot = null;
                              });
                              _loadAvailableSlots();
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
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Available Time Slots
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Time Slots',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_availableSlots.isEmpty)
                            Center(
                              child: Text(
                                'No available slots for this day',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _availableSlots.map((slot) {
                                    final isSelected =
                                        _selectedSlot?.id == slot.id;
                                    return ChoiceChip(
                                      label: Text(
                                        '${slot.startTime.hour}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.poppins(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedSlot = slot);
                                        }
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: AppColors.primary,
                                    );
                                  }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any notes or special requests...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Update Button
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: CustomButton(
                        text: 'Update Appointment',
                        onPressed:
                            _isLoading ? () {} : () => _updateAppointment(),
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
