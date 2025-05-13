import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
// import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String? doctorId; // Made doctorId optional
  final bool isOwnProfile;

  const DoctorProfileScreen({super.key, this.doctorId , this.isOwnProfile = true});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isEditing = false;

  // Dummy data for the Doctor
  final Doctor _doctor = Doctor(
    id: 'doc1',
    name: 'Dr. John Smith',
    email: 'john@example.com',
    specialty: 'Cardiologist',
    qualifications: 'MD, PhD',
    clinicAddress: '123 Heart St, City',
    workingHours: {
      'Monday': '9:00-17:00',
      'Tuesday': '9:00-17:00',
      'Wednesday': '9:00-17:00',
      'Thursday': '9:00-17:00',
      'Friday': '9:00-17:00',
    },
    commissionRate: 10.0,
  );

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _specialtyController;
  late TextEditingController _qualificationsController;
  late TextEditingController _clinicAddressController;
  final Map<String, TextEditingController> _workingHoursControllers = {};

  @override
  void initState() {
    super.initState();
    // If doctorId is provided, fetch the Doctor's data (simulated here)
    // For now, we use the dummy _doctor data regardless of doctorId
    _nameController = TextEditingController(text: _doctor.name);
    _emailController = TextEditingController(text: _doctor.email);
    _specialtyController = TextEditingController(text: _doctor.specialty);
    _qualificationsController = TextEditingController(text: _doctor.qualifications);
    _clinicAddressController = TextEditingController(text: _doctor.clinicAddress);
    _doctor.workingHours.forEach((day, hours) {
      _workingHoursControllers[day] = TextEditingController(text: hours);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _qualificationsController.dispose();
    _clinicAddressController.dispose();
    _workingHoursControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _toggleEditMode() {
    // Only allow editing if doctorId is null (Doctor's own profile)
    if (widget.doctorId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot edit this profile')),
      );
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes (simulated)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    });
  }

  void _logout() {
    Navigator.pushNamed(context , RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is the Doctor's own profile or a patient-facing view
    final isOwnProfile = widget.doctorId == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isOwnProfile ? 'My Profile' : 'Doctor Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: isOwnProfile
            ? [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: AppColors.primary,
            ),
            onPressed: _toggleEditMode,
          ),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            FadeInDown(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _doctor.name[0],
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.defaultPadding),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _doctor.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _doctor.specialty,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Basic Info
            FadeInUp(
              child: Text(
                'Basic Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: CustomTextField(
                hintText: 'Name',
                controller: _nameController,
                enabled: _isEditing && isOwnProfile,
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: CustomTextField(
                hintText: 'Email',
                controller: _emailController,
                enabled: false, // Email typically shouldn't be editable
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: CustomTextField(
                hintText: 'Specialty',
                controller: _specialtyController,
                enabled: _isEditing && isOwnProfile,
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: CustomTextField(
                hintText: 'Qualifications',
                controller: _qualificationsController,
                enabled: _isEditing && isOwnProfile,
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: CustomTextField(
                hintText: 'Clinic Address',
                controller: _clinicAddressController,
                enabled: _isEditing && isOwnProfile,
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Working Hours
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'Working Hours',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            ..._workingHoursControllers.entries.map((entry) {
              final day = entry.key;
              final controller = entry.value;
              return FadeInUp(
                delay: Duration(milliseconds: 700 + 100 * _workingHoursControllers.keys.toList().indexOf(day)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          day,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          hintText: 'e.g., 9:00-17:00',
                          controller: controller,
                          enabled: _isEditing && isOwnProfile,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: AppSizes.largePadding),

            // Commission Rate (Read-only, set by Admin, only visible for Doctor's own profile)
            if (isOwnProfile) ...[
              FadeInUp(
                child: Text(
                  'Commission Rate',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.defaultPadding),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: CustomTextField(
                  hintText: 'Commission Rate',
                  controller: TextEditingController(text: '${_doctor.commissionRate}%'),
                  enabled: false, // Set by Admin
                ),
              ),
              const SizedBox(height: AppSizes.largePadding),
            ],

            // Logout Button (only for Doctor's own profile)
            if (isOwnProfile)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: CustomButton(
                  text: 'Logout',
                  color: AppColors.error,
                  onPressed: _logout,
                ),
              ),
          ],
        ),
      ),
    );
  }
}