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
// import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      setState(() => _isLoading = true);
      // Dummy login logic (replace with Firebase later)
      print('Login: ${_emailController.text}, ${_selectedRole}');
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in as ${_selectedRole!.name}')),
        );
        // Navigate based on role
        switch (_selectedRole!) {
          case UserRole.patient:
            Navigator.pushNamed(context, RouteNames.home); // Navigate to Patient HomeScreen
            break;
          case UserRole.doctor:
            Navigator.pushNamed(context, RouteNames.doctorHome); // Navigate to Doctor HomeScreen
            break;
          case UserRole.admin:
          // Placeholder for Admin dashboard (to be implemented)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin dashboard coming soon!')),
            );
            break;
        }
      });
    } else if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.smallPadding),
                Text(
                  'Log in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.largePadding),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: AppStrings.emailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty || !value.contains('@')
                            ? 'Please enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomTextField(
                        hintText: AppStrings.passwordHint,
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: AppSizes.largePadding),

                      // Role Selection
                      Text(
                        'Select Role',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.smallPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildRoleChip(AppStrings.patientRole, UserRole.patient),
                          _buildRoleChip(AppStrings.doctorRole, UserRole.doctor),
                          _buildRoleChip(AppStrings.adminRole, UserRole.admin),
                        ],
                      ),
                      const SizedBox(height: AppSizes.largePadding),

                      // Login Button
                      CustomButton(
                        text: AppStrings.login,
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),

                // Forgot Password and Sign Up Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, RouteNames.forgotPassword),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'New here? ',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RouteNames.signUp),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, UserRole role) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRole == role,
      onSelected: (selected) {
        setState(() => _selectedRole = selected ? role : null);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: GoogleFonts.poppins(
        color: _selectedRole == role ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }
}