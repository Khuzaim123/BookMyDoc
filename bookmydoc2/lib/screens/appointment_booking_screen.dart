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
// import 'package:go_router/go_router.dart';

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

  // Dummy doctor and availability data
  Doctor getDoctor() {
    return Doctor(
      id: widget.doctorId,
      name: 'Dr. John Smith',
      email: 'john@example.com',
      specialty: 'Cardiologist',
      qualifications: 'MD, PhD',
      clinicAddress: '123 Heart St',
      workingHours: {'Monday': '9:00-17:00'},
    );
  }

  List<DoctorAvailability> getAvailability() {
    return [
      DoctorAvailability(
        id: 'slot1',
        doctorId: widget.doctorId,
        startTime: DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          9,
        ),
        endTime: DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          9,
          30,
        ),
      ),
      DoctorAvailability(
        id: 'slot2',
        doctorId: widget.doctorId,
        startTime: DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          10,
        ),
        endTime: DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          10,
          30,
        ),
      ),
    ];
  }

  void _bookAppointment() {
    if (_selectedSlot != null) {
      setState(() => _isLoading = true);
      // Dummy booking logic
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment booked!')));
        Navigator.pushNamed(context, RouteNames.appointments);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = getDoctor();
    final availability = getAvailability();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book with ${doctor.name}',
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
            Wrap(
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
                                  () => _selectedSlot = selected ? slot : null,
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
