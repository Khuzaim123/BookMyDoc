import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/doctor.dart';
import '../models/reminder.dart';
import '../models/user_image.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String? doctorId;
  final bool isOwnProfile;

  const DoctorProfileScreen({
    super.key,
    this.doctorId,
    this.isOwnProfile = true,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool _isLoading = true;
  late Doctor _doctor;
  UserImage? _userImage;
  String? _errorMessage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _specialtyController;
  late TextEditingController _qualificationsController;
  late TextEditingController _clinicAddressController;
  final Map<String, TextEditingController> _workingHoursControllers = {};

  final TextEditingController _feedbackController = TextEditingController();

  final List<Reminder> _reminders = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: widget.isOwnProfile ? 3 : 1,
      vsync: this,
    );

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _specialtyController = TextEditingController();
    _qualificationsController = TextEditingController();
    _clinicAddressController = TextEditingController();

    _fetchDoctorData();

    _loadUserImage(widget.doctorId ?? _auth.currentUser?.uid);

    if (widget.isOwnProfile) {
      _fetchReminders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _qualificationsController.dispose();
    _clinicAddressController.dispose();
    _feedbackController.dispose();
    _workingHoursControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchDoctorData() async {
    setState(() => _isLoading = true);

    try {
      String doctorId =
          widget.doctorId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

      DocumentSnapshot doctorDoc =
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(doctorId)
              .get();

      if (doctorDoc.exists) {
        Map<String, dynamic> data = doctorDoc.data() as Map<String, dynamic>;

        Map<String, String> workingHours = {};
        if (data['workingHours'] != null) {
          (data['workingHours'] as Map<String, dynamic>).forEach((key, value) {
            workingHours[key] = value.toString();
          });
        }

        _doctor = Doctor(
          id: doctorDoc.id,
          name: data['name'] ?? 'Unknown Doctor',
          email: data['email'] ?? '',
          specialty: data['specialty'] ?? '',
          qualifications: data['qualification'] ?? '',
          clinicAddress: data['clinicAddress'] ?? '',
          workingHours: workingHours,
          rating: (data['rating'] as num?)?.toDouble(),
          experience: (data['experience'] as num?)?.toDouble(),
          consultationFee: (data['consultationFee'] as num?)?.toDouble(),
        );

        _nameController.text = _doctor.name;
        _emailController.text = _doctor.email;
        _specialtyController.text = _doctor.specialty;
        _qualificationsController.text = _doctor.qualifications;
        _clinicAddressController.text = _doctor.clinicAddress;

        _doctor.workingHours.forEach((day, hours) {
          _workingHoursControllers[day] = TextEditingController(text: hours);
        });

        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ].forEach((day) {
          if (!_workingHoursControllers.containsKey(day)) {
            _workingHoursControllers[day] = TextEditingController(
              text: 'Not available',
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile not found')),
        );

        _doctor = Doctor(
          id: doctorId,
          name: 'Unknown Doctor',
          email: '',
          specialty: '',
          qualifications: '',
          clinicAddress: '',
          workingHours: {},
        );

        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ].forEach((day) {
          _workingHoursControllers[day] = TextEditingController(
            text: 'Not available',
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );

      _doctor = Doctor(
        id: widget.doctorId ?? 'unknown',
        name: 'Error loading data',
        email: '',
        specialty: '',
        qualifications: '',
        clinicAddress: '',
        workingHours: {},
      );

      [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ].forEach((day) {
        _workingHoursControllers[day] = TextEditingController(
          text: 'Not available',
        );
      });
    } finally {
      if (_userImage != null) {
        setState(() => _isLoading = false);
      } else if (_userImage == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserImage(String? userId) async {
    if (userId == null) return;

    try {
      final userImageSnapshot =
          await _firestore.collection('userImages').doc(userId).get();

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
      if (_doctor != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (!widget.isOwnProfile) return;

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

  Future<void> _fetchReminders() async {
    try {
      String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (doctorId.isEmpty) return;

      QuerySnapshot reminderDocs =
          await FirebaseFirestore.instance
              .collection('reminders')
              .where('patientId', isEqualTo: doctorId)
              .orderBy('time')
              .get();

      List<Reminder> reminders = [];
      for (var doc in reminderDocs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        DateTime time;
        if (data['time'] is Timestamp) {
          time = (data['time'] as Timestamp).toDate();
        } else {
          time = DateTime.now();
        }

        reminders.add(
          Reminder(
            id: doc.id,
            userid: data['patientId'] ?? '',
            task: data['task'] ?? 'No description',
            time: time,
          ),
        );
      }

      setState(() {
        _reminders.clear();
        _reminders.addAll(reminders);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reminders: ${e.toString()}')),
      );
      print('Error loading reminders: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!widget.isOwnProfile) return;

    try {
      Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'specialty': _specialtyController.text,
        'qualification': _qualificationsController.text,
        'clinicAddress': _clinicAddressController.text,
        'workingHours': _workingHoursControllers.map(
          (day, controller) => MapEntry(day, controller.text),
        ),
      };

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(_doctor.id)
          .update(updatedData);

      setState(() {
        _doctor = Doctor(
          id: _doctor.id,
          name: _nameController.text,
          email: _doctor.email,
          specialty: _specialtyController.text,
          qualifications: _qualificationsController.text,
          clinicAddress: _clinicAddressController.text,
          workingHours: _workingHoursControllers.map(
            (day, controller) => MapEntry(day, controller.text),
          ),
          rating: _doctor.rating,
          experience: _doctor.experience,
          consultationFee: _doctor.consultationFee,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
      print('Error updating profile: $e');
    }
  }

  void _toggleEditMode() {
    if (!widget.isOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot edit this profile')),
      );
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _updateProfile();
      } else {
        _nameController.text = _doctor.name;
        _emailController.text = _doctor.email;
        _specialtyController.text = _doctor.specialty;
        _qualificationsController.text = _doctor.qualifications;
        _clinicAddressController.text = _doctor.clinicAddress;
        _workingHoursControllers.forEach((day, controller) {
          controller.text = _doctor.workingHours[day] ?? 'Not available';
        });
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      Map<String, dynamic> feedbackData = {
        'userId': userId,
        'content': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userRole': 'doctor',
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: ${e.toString()}')),
      );
      print('Error submitting feedback: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
      print('Error signing out: $e');
    }
  }

  Future<void> _addReminder() async {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();
        DateTime selectedDate = DateTime.now();
        TimeOfDay selectedTime = TimeOfDay.now();

        return AlertDialog(
          title: const Text('Add Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Description',
                    hintText: 'Enter reminder details',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text('${selectedTime.hour}:${selectedTime.minute}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      selectedTime = pickedTime;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (taskController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a description')),
                  );
                  return;
                }

                final DateTime reminderTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  String doctorId =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (doctorId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User not authenticated to add reminder'),
                      ),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection('reminders').add({
                    'patientId': doctorId,
                    'task': taskController.text,
                    'time': Timestamp.fromDate(reminderTime),
                    'isCompleted': false,
                  });

                  _fetchReminders();

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving reminder: ${e.toString()}'),
                    ),
                  );
                  print('Error saving reminder: $e');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.smallPadding),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required bool isEditing,
    required String value,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSizes.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                      controller: controller,
                      enabled: enabled,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                    : Text(
                      value.isEmpty ? 'Not specified' : value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursItem({
    required String day,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child:
                isEditing
                    ? TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'e.g. 9:00 AM - 5:00 PM',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                    : Text(
                      controller.text.isEmpty
                          ? 'Not available'
                          : controller.text,
                      style: GoogleFonts.poppins(),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isOwnProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isOwnProfile ? _pickAndUploadImage : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage:
                          _userImage?.imageUrl != null
                              ? NetworkImage(_userImage!.imageUrl)
                              : null,
                      child:
                          _userImage?.imageUrl == null
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing && isOwnProfile
                      ? TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      )
                      : Text(
                        _doctor.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  if (_doctor.rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${_doctor.rating!.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.largePadding),

          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildSection(
              title: 'Specialty',
              children: [
                _buildInfoItem(
                  icon: Icons.medical_services,
                  title: 'Specialty',
                  controller: _specialtyController,
                  isEditing: _isEditing && isOwnProfile,
                  value: _doctor.specialty,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.defaultPadding),

          FadeInUp(
            delay: const Duration(milliseconds: 150),
            child: _buildSection(
              title: 'Qualifications',
              children: [
                _buildInfoItem(
                  icon: Icons.school,
                  title: 'Degrees',
                  controller: _qualificationsController,
                  isEditing: _isEditing && isOwnProfile,
                  value: _doctor.qualifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.defaultPadding),

          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildSection(
              title: 'Contact Information',
              children: [
                _buildInfoItem(
                  icon: Icons.email,
                  title: 'Email',
                  controller: _emailController,
                  isEditing: _isEditing && isOwnProfile,
                  value: _doctor.email,
                  enabled: false,
                ),
                _buildInfoItem(
                  icon: Icons.location_on,
                  title: 'Clinic Address',
                  controller: _clinicAddressController,
                  isEditing: _isEditing && isOwnProfile,
                  value: _doctor.clinicAddress,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.defaultPadding),

          FadeInUp(
            delay: const Duration(milliseconds: 250),
            child: _buildSection(
              title: 'Working Hours',
              children: [
                ...[
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ]
                    .map(
                      (day) => _buildWorkingHoursItem(
                        day: day,
                        controller: _workingHoursControllers[day]!,
                        isEditing: _isEditing && isOwnProfile,
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.defaultPadding),

          if (!isOwnProfile)
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Book Appointment',
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.appointmentBooking,
                        arguments: {"id": widget.doctorId},
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.defaultPadding),
                  CustomButton(
                    text: 'Message Doctor',
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.message,
                        arguments: {
                          "id": widget.doctorId,
                          "name": _doctor.name,
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

          if (isOwnProfile)
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Change Password',
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.changePassword);
                    },
                  ),
                  CustomButton(
                    text: 'Logout',
                    color: AppColors.error,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Reminders',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FloatingActionButton(
                mini: true,
                onPressed: _addReminder,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _reminders.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        Text(
                          'No reminders yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: AppSizes.smallPadding),
                        Text(
                          'Tap the + button to add a reminder',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _reminders.length,
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 50),
                        child: Dismissible(
                          key: Key(reminder.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppColors.error,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('reminders')
                                  .doc(reminder.id)
                                  .delete();

                              setState(() {
                                _reminders.removeAt(index);
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error deleting reminder: ${e.toString()}',
                                  ),
                                ),
                              );
                              print('Error deleting reminder: $e');
                            }
                          },
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                reminder.task,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${reminder.time.day}/${reminder.time.month}/${reminder.time.year} at ${reminder.time.hour}:${reminder.time.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.notifications_active),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Feedback',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.defaultPadding),
          Text(
            'We appreciate your feedback to improve our services. Please share your thoughts below:',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSizes.defaultPadding),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write your feedback here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.defaultPadding),
          CustomButton(
            text: 'Submit Feedback',
            color: AppColors.primary,
            onPressed: _submitFeedback,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.isOwnProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwnProfile ? 'My Profile' : 'Doctor Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _toggleEditMode,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs:
              isOwnProfile
                  ? const [
                    Tab(text: 'Profile', icon: Icon(Icons.person)),
                    Tab(text: 'Reminders', icon: Icon(Icons.notifications)),
                    Tab(text: 'Feedback', icon: Icon(Icons.feedback)),
                  ]
                  : const [Tab(text: 'Profile', icon: Icon(Icons.person))],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _doctor == null
              ? Center(
                child: Text(_errorMessage ?? 'Error loading profile data'),
              )
              : TabBarView(
                controller: _tabController,
                children:
                    isOwnProfile
                        ? [
                          _buildProfileTab(isOwnProfile),
                          _buildRemindersTab(),
                          _buildFeedbackTab(),
                        ]
                        : [_buildProfileTab(isOwnProfile)],
              ),
    );
  }
}
