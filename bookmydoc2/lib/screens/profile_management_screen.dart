import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/patient.dart';
import '../models/reminder.dart';
import '../models/user_image.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Patient? _patient;
  UserImage? _userImage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserImage();
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final patientSnapshot =
          await _firestore.collection('patients').doc(currentUser.uid).get();

      if (patientSnapshot.exists) {
        final data = patientSnapshot.data() as Map<String, dynamic>;
        _patient = Patient(
          id: currentUser.uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
        );

        _nameController.text = _patient!.name;
        _emailController.text = _patient!.email;
        _phoneController.text = _patient!.phone;
      } else {
        throw Exception('User data not found in patients collection');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading profile data: $e');
    } finally {
      if (_patient != null && _userImage != null) {
        setState(() => _isLoading = false);
      } else if (_patient != null && _userImage == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserImage() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userImageSnapshot =
          await _firestore.collection('userImages').doc(currentUser.uid).get();

      if (userImageSnapshot.exists) {
        final data = userImageSnapshot.data() as Map<String, dynamic>;
        _userImage = UserImage.fromFirestore(data);
      } else {
        _userImage = null;
      }
    } catch (e) {
      print('Error loading user image: $e');
      _userImage = null;
    } finally {
      if (_patient != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final storageRef = _storage.ref().child(
          'userImages/${currentUser.uid}/profile.png',
        );

        final uploadTask = storageRef.putFile(File(pickedFile.path));

        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('userImages').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'imageUrl': downloadUrl,
        });

        setState(() {
          _userImage = UserImage(
            userId: currentUser.uid,
            imageUrl: downloadUrl,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload picture: ${e.toString()}')),
      );
      print('Error uploading picture: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      await _firestore.collection('patients').doc(currentUser.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });

      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });

      setState(() {
        _patient = Patient(
          id: currentUser.uid,
          name: _nameController.text,
          email: _patient!.email,
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

  Future<void> _addReminder() async {
    if (_reminderTaskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder task')),
      );
      return;
    }

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

      await _firestore.collection('reminders').add({
        'patientId': currentUser.uid,
        'task': _reminderTaskController.text,
        'time': Timestamp.fromDate(_reminderTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _reminderTaskController.clear();
      _reminderTime = DateTime.now().add(const Duration(hours: 1));

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
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage:
                                  _userImage?.imageUrl != null
                                      ? NetworkImage(_userImage!.imageUrl)
                                      : null,
                              child:
                                  _userImage?.imageUrl == null
                                      ? Icon(
                                        Icons.person,
                                        size: 70,
                                        color: AppColors.primary,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),

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
                            enabled: false,
                          ),
                          const SizedBox(height: AppSizes.defaultPadding),
                          CustomTextField(
                            hintText: 'Enter your phone number',
                            controller: _phoneController,
                            prefixIcon: Icons.phone,
                          ),
                          const SizedBox(height: AppSizes.largePadding),

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

                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
