import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/user.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.patient; // Default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      // Simulate sign-up process (replace with Firebase Auth later)
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        // Create a User object (to be stored in Firestore later)
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          name: _nameController.text,
          email: _emailController.text,
          role: _selectedRole,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful!')),
        );
        // Navigate based on role
        if (_selectedRole == UserRole.patient) {
          Navigator.pushNamed(context, RouteNames.home);
        } else if (_selectedRole == UserRole.doctor) {
          Navigator.pushNamed(context, RouteNames.doctorHome);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeInDown(
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.smallPadding),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Sign up to get started',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.largePadding),

                // Role Selection
                FadeInUp(
                  child: Text(
                    'I am a:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.smallPadding),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: Text(
                            'Patient',
                            style: GoogleFonts.poppins(),
                          ),
                          value: UserRole.patient,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: Text(
                            'Doctor',
                            style: GoogleFonts.poppins(),
                          ),
                          value: UserRole.doctor,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),

                // Form Fields
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: CustomTextField(
                    hintText: AppStrings.nameHint,
                    controller: _nameController,
                    validator: _validateName,
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: CustomTextField(
                    hintText: AppStrings.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: CustomTextField(
                    hintText: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: CustomTextField(
                    hintText: AppStrings.passwordHint,
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                ),
                const SizedBox(height: AppSizes.largePadding),

                // Sign Up Button
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: CustomButton(
                    text: 'Sign Up',
                    onPressed: _signUp,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),

                // Login Link
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, RouteNames.login),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}