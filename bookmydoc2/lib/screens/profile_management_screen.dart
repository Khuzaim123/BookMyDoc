import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient.dart';
import '../models/reminder.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';
import '../routes.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _reminderTaskController = TextEditingController();
  DateTime _reminderTime = DateTime.now();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Patient? _patient;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
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

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get user data from Firestore
      final patientSnapshot =
          await _firestore.collection('patients').doc(currentUser.uid).get();

      if (patientSnapshot.exists) {
        // Create user object from snapshot
        final data = patientSnapshot.data() as Map<String, dynamic>;
        _patient = Patient(
          id: currentUser.uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
        );

        // Set text controllers
        _nameController.text = _patient!.name;
        _emailController.text = _patient!.email;
        _phoneController.text = _patient!.phone;

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading profile: $e');
    }
  }

  // Update profile in Firestore
  Future<void> _updateProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Validate input
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      // Update in Firestore
      await _firestore.collection('patients').doc(currentUser.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });

      // Also update in users collection
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });

      // Update local state
      setState(() {
        _patient = Patient(
          id: currentUser.uid,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
      print('Error updating profile: $e');
    }
  }

  // Sign out user
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
      print('Error signing out: $e');
    }
  }

  // Submit feedback to Firestore
  Future<void> _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Add feedback to Firestore
      await _firestore.collection('feedback').add({
        'patientId': currentUser.uid,
        'content': _feedbackController.text,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: ${e.toString()}')),
      );
      print('Error submitting feedback: $e');
    }
  }

  // Add reminder to Firestore
  Future<void> _addReminder() async {
    if (_reminderTaskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder task')),
      );
      return;
    }

    // Validate that reminder time is in the future
    if (_reminderTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future time for the reminder'),
        ),
      );
      return;
    }

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Add new reminder to Firestore
      await _firestore.collection('reminders').add({
        'patientId': currentUser.uid,
        'task': _reminderTaskController.text,
        'time': Timestamp.fromDate(_reminderTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _reminderTaskController.clear();
      _reminderTime = DateTime.now().add(const Duration(hours: 1));

      // Reload reminders from Firestore to ensure UI is up to date
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reminder: ${e.toString()}')),
      );
      print('Error adding reminder: $e');
    }
  }

  // Delete reminder from Firestore
  Future<void> _deleteReminder(String reminderId, int index) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).delete();
      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete reminder: ${e.toString()}')),
      );
      print('Error deleting reminder: $e');
    }
  }

  // Helper function to show date time picker
  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) return null;

    if (!context.mounted) return selectedDate;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return selectedDate;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Reminders'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                controller: _tabController,
                children: [
                  // Profile Tab
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      child: Column(
                        children: [
                          // Profile Picture
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),

                          // Profile Information Form
                          CustomTextField(
                            hintText: 'Enter your full name',
                            controller: _nameController,
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          CustomTextField(
                            hintText: 'Enter your email',
                            controller: _emailController,
                            prefixIcon: Icons.email,
                            enabled: false, // Email can't be changed
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          CustomTextField(
                            hintText: 'Enter your phone number',
                            controller: _phoneController,
                            prefixIcon: Icons.phone,
                          ),
                          const SizedBox(height: AppSizes.largePadding),

                          // Change Password Button
                          CustomButton(
                            text: 'Change Password',
                            color: AppColors.primary,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.changePassword,
                              );
                            },
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),

                          // Update and Logout Buttons
                          CustomButton(
                            text: 'Update Profile',
                            onPressed: _updateProfile,
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          CustomButton(
                            text: 'Logout',
                            color: AppColors.error,
                            onPressed: _signOut,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reminders Tab
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream:
                                  _firestore
                                      .collection('reminders')
                                      .where(
                                        'patientId',
                                        isEqualTo: _auth.currentUser?.uid,
                                      )
                                      .orderBy('time')
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No reminders yet',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data =
                                        docs[index].data()
                                            as Map<String, dynamic>;
                                    final reminder = Reminder(
                                      id: docs[index].id,
                                      userid: data['patientId'],
                                      task: data['task'],
                                      time:
                                          (data['time'] as Timestamp).toDate(),
                                    );
                                    return FadeInUp(
                                      delay: Duration(
                                        milliseconds: index * 100,
                                      ),
                                      child: CustomCard(
                                        child: ListTile(
                                          title: Text(
                                            reminder.task,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${reminder.time.day}/${reminder.time.month}/${reminder.time.year} at ${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.error,
                                            ),
                                            onPressed:
                                                () => _deleteReminder(
                                                  reminder.id,
                                                  index,
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          FadeInDown(
                            child: Column(
                              children: [
                                CustomTextField(
                                  hintText:
                                      'Reminder task (e.g., Take medication)',
                                  controller: _reminderTaskController,
                                ),
                                const SizedBox(height: AppSizes.defaultPadding),
                                ElevatedButton(
                                  onPressed: () async {
                                    final picked = await showDateTimePicker(
                                      context: context,
                                      initialDate: _reminderTime,
                                    );
                                    if (picked != null)
                                      setState(() => _reminderTime = picked);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.buttonRadius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Set Time: ${_reminderTime.day}/${_reminderTime.month}/${_reminderTime.year} at ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
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
                  ),

                  // Feedback Tab
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Feedback form
                          const Text(
                            'We value your feedback!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          const Text(
                            'Please let us know how we can improve BookMyDoc to serve you better.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSizes.largePadding),
                          CustomTextField(
                            hintText: 'Enter your feedback here',
                            controller: _feedbackController,
                            maxLines: 5,
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
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
}
