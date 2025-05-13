import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/doctor_availability.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String doctorId;

  const DoctorAvailabilityScreen({super.key, required this.doctorId});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final _uuid = const Uuid();
  bool _isLoading = false;
  String? _error;
  List<DoctorAvailability> _availabilities = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorAvailability();
  }

  Future<void> _loadDoctorAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('doctor_availabilities')
              .where('doctorId', isEqualTo: widget.doctorId)
              .get();

      setState(() {
        _availabilities =
            snapshot.docs
                .map((doc) => DoctorAvailability.fromJson(doc.data()))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addAvailability() async {
    final startTime = await showDateTimePicker(
      context: context,
      initialDate: DateTime.now(),
    );
    if (startTime == null) return;
    final endTime = await showDateTimePicker(
      context: context,
      initialDate: startTime.add(const Duration(minutes: 30)),
    );
    if (endTime == null) return;

    final availability = DoctorAvailability(
      id: _uuid.v4(),
      doctorId: widget.doctorId,
      startTime: startTime,
      endTime: endTime,
      isBooked: false,
    );

    try {
      await FirebaseFirestore.instance
          .collection('doctor_availabilities')
          .doc(availability.id)
          .set(availability.toJson());

      await _loadDoctorAvailability();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability slot added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding availability: $e')),
        );
      }
    }
  }

  void _deleteAvailability(DoctorAvailability availability) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctor_availabilities')
          .doc(availability.id)
          .delete();

      await _loadDoctorAvailability();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability slot deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting availability: $e')),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Availability',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  'Error: $_error',
                  style: GoogleFonts.poppins(color: AppColors.error),
                ),
              )
              : Column(
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
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
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
                          titleTextStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                          formatButtonVisible: false,
                        ),
                      ),
                    ),
                  ),

                  // Availability Slots
                  Expanded(
                    child:
                        _availabilities
                                .where(
                                  (avail) =>
                                      avail.startTime.year ==
                                          _selectedDay.year &&
                                      avail.startTime.month ==
                                          _selectedDay.month &&
                                      avail.startTime.day == _selectedDay.day,
                                )
                                .isEmpty
                            ? Center(
                              child: FadeInUp(
                                child: Text(
                                  'No availability slots for this day',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(
                                AppSizes.defaultPadding,
                              ),
                              itemCount:
                                  _availabilities
                                      .where(
                                        (avail) =>
                                            avail.startTime.year ==
                                                _selectedDay.year &&
                                            avail.startTime.month ==
                                                _selectedDay.month &&
                                            avail.startTime.day ==
                                                _selectedDay.day,
                                      )
                                      .length,
                              itemBuilder: (context, index) {
                                final availability =
                                    _availabilities
                                        .where(
                                          (avail) =>
                                              avail.startTime.year ==
                                                  _selectedDay.year &&
                                              avail.startTime.month ==
                                                  _selectedDay.month &&
                                              avail.startTime.day ==
                                                  _selectedDay.day,
                                        )
                                        .toList()[index];
                                return FadeInUp(
                                  delay: Duration(milliseconds: index * 100),
                                  child: CustomCard(
                                    child: ListTile(
                                      title: Text(
                                        '${availability.startTime.hour}:${availability.startTime.minute.toString().padLeft(2, '0')} - '
                                        '${availability.endTime.hour}:${availability.endTime.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        availability.isBooked
                                            ? 'Booked'
                                            : 'Available',
                                        style: GoogleFonts.poppins(
                                          color:
                                              availability.isBooked
                                                  ? AppColors.error
                                                  : Colors.green,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.error,
                                        ),
                                        onPressed:
                                            () => _deleteAvailability(
                                              availability,
                                            ),
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
