import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/doctor_availability.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final List<DoctorAvailability> _availabilities = [
    DoctorAvailability(
      id: 'avail1',
      doctorId: 'doc1',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      isBooked: false,
    ),
  ];

  void _addAvailability() async {
    final startTime = await showDateTimePicker(context: context, initialDate: DateTime.now());
    if (startTime == null) return;
    final endTime = await showDateTimePicker(context: context, initialDate: startTime.add(const Duration(minutes: 30)));
    if (endTime == null) return;

    setState(() {
      _availabilities.add(DoctorAvailability(
        id: 'avail${_availabilities.length + 1}',
        doctorId: 'doc1',
        startTime: startTime,
        endTime: endTime,
        isBooked: false,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Availability slot added!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAvailabilities = _availabilities
        .where((avail) =>
    avail.startTime.year == _selectedDay.year &&
        avail.startTime.month == _selectedDay.month &&
        avail.startTime.day == _selectedDay.day)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Availability',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: FadeInDown(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  formatButtonVisible: false,
                ),
              ),
            ),
          ),

          // Availability Slots
          Expanded(
            child: filteredAvailabilities.isEmpty
                ? Center(
              child: FadeInUp(
                child: Text(
                  'No availability slots for this day',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              itemCount: filteredAvailabilities.length,
              itemBuilder: (context, index) {
                final availability = filteredAvailabilities[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: CustomCard(
                    child: ListTile(
                      title: Text(
                        '${availability.startTime.hour}:${availability.startTime.minute.toString().padLeft(2, '0')} - '
                            '${availability.endTime.hour}:${availability.endTime.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        availability.isBooked ? 'Booked' : 'Available',
                        style: GoogleFonts.poppins(
                          color: availability.isBooked ? AppColors.error : Colors.green,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _availabilities.remove(availability);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Availability slot deleted')),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAvailability,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}