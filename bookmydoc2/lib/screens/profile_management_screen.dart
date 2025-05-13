import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/app_feedback.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/models/reminder.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:go_router/go_router.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'Patient Name');
  final _emailController = TextEditingController(text: 'patient@example.com');
  final _phoneController = TextEditingController(text: '+1234567890'); // Added phone field
  final _feedbackController = TextEditingController();
  final _reminderTaskController = TextEditingController();
  DateTime _reminderTime = DateTime.now();

  // Dummy data
  final Patient patient = Patient(
    id: 'patient1',
    name: 'Patient Name',
    email: 'patient@example.com',
    phone: '+1234567890', // Added phone to Patient model
  );

  final List<Reminder> reminders = [
    Reminder(
      id: 'rem1',
      patientId: 'patient1',
      task: 'Take medication',
      time: DateTime.now().add(const Duration(hours: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _feedbackController.dispose();
    _reminderTaskController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    // Simulate profile update (replace with actual Firebase update later)
    setState(() {
      patient.name = _nameController.text;
      patient.email = _emailController.text;
      patient.phone = _phoneController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _addReminder() {
    if (_reminderTaskController.text.isNotEmpty) {
      setState(() {
        reminders.add(Reminder(
          id: 'rem${reminders.length + 1}',
          patientId: patient.id,
          task: _reminderTaskController.text,
          time: _reminderTime,
        ));
        _reminderTaskController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder task')),
      );
    }
  }

  void _submitFeedback() {
    if (_feedbackController.text.isNotEmpty) {
      AppFeedback feedback = AppFeedback(
        id: 'fb${DateTime.now().millisecondsSinceEpoch}',
        patientId: patient.id,
        content: _feedbackController.text,
        submittedAt: DateTime.now(),
      );
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
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
          'Profile Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Reminders'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: FadeInDown(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Placeholder
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Placeholder for profile picture upload
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile picture upload coming soon!')),
                        );
                      },
                      child: Text(
                        'Change Profile Picture',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.largePadding),

                  // Profile Fields
                  Text(
                    'Personal Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomTextField(
                    hintText: AppStrings.nameHint,
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomTextField(
                    hintText: AppStrings.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomTextField(
                    hintText: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSizes.largePadding),

                  // Update and Logout Buttons
                  CustomButton(
                    text: 'Update Profile',
                    onPressed: _updateProfile,
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomButton(
                    text: 'Logout',
                    color: AppColors.error,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.login),
                  ),
                ],
              ),
            ),
          ),

          // Reminders Tab
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Column(
              children: [
                Expanded(
                  child: reminders.isEmpty
                      ? Center(
                    child: Text(
                      'No reminders yet',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                  )
                      : ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: CustomCard(
                          child: ListTile(
                            title: Text(
                              reminder.task,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              reminder.time.toString().substring(0, 16),
                              style: GoogleFonts.poppins(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  reminders.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reminder deleted!')),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                FadeInDown(
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: 'Reminder task (e.g., Take medication)',
                        controller: _reminderTaskController,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDateTimePicker(
                            context: context,
                            initialDate: _reminderTime,
                          );
                          if (picked != null) setState(() => _reminderTime = picked);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                          ),
                        ),
                        child: Text(
                          'Set Time: ${_reminderTime.toString().substring(0, 16)}',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomButton(
                        text: 'Add Reminder',
                        onPressed: _addReminder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Feedback Tab
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: FadeInUp(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Your Feedback',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomTextField(
                    hintText: 'Your feedback about the app...',
                    controller: _feedbackController,
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSizes.largePadding),
                  CustomButton(
                    text: 'Submit Feedback',
                    onPressed: _submitFeedback,
                  ),
                ],
              ),
            ),
          ),
        ],
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