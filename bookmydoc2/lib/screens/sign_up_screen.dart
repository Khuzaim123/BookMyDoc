import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';

// Step 1: Create an enum for user roles
enum UserRole {
  patient,
  doctor,
}

// Step 2: Main SignUpScreen class
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  
  // Firebase instances
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validation methods
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

  // Email/Password Sign Up Function
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        // Create user with email and password
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        final user = userCredential.user;
        
        if (user != null) {
          // Send email verification
          await user.sendEmailVerification();
          
          // Store basic user data temporarily
          final userData = {
            'id': user.uid,
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-up successful! Please check your email for verification.')),
          );
          
          // Navigate to RoleSelectionScreen
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoleSelectionScreen(
                user: user,
                userData: userData,
                isGoogleSignIn: false,
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Safely display error message without trying to convert the entire exception
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().split(']').last.trim()}')),
        );
      }
    }
  }
  
  // Google Sign In Function
  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isGoogleLoading = true;
      });
      
      // Begin Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in flow
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Store basic user data temporarily
        final userData = {
          'id': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        setState(() {
          _isGoogleLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in successful!')),
        );
        
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!context.mounted) return;
        
        // If user exists and has a role, navigate to appropriate home screen
        if (userDoc.exists) {
          final existingUserData = userDoc.data() as Map<String, dynamic>;
          if (existingUserData.containsKey('role')) {
            // Navigate based on role
            if (existingUserData['role'] == 'patient') {
              Navigator.pushReplacementNamed(context, RouteNames.home);
            } else if (existingUserData['role'] == 'doctor') {
              Navigator.pushReplacementNamed(context, RouteNames.doctorHome);
            }
            return;
          }
        }
        
        // If user doesn't exist or doesn't have a role, navigate to role selection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              user: user,
              userData: userData,
              isGoogleSignIn: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGoogleLoading = false;
      });
      
      // Safely display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().split(']').last.trim()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo and Title
                FadeInDown(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_hospital_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSizes.smallPadding),
                      Text(
                        AppStrings.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.smallPadding),
                      Text(
                        'Create an Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),

                // Sign Up Form
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Basic fields for all users
                        CustomTextField(
                          hintText: AppStrings.nameHint,
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                          validator: _validateName,
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        CustomTextField(
                          hintText: AppStrings.emailHint,
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        CustomTextField(
                          hintText: 'Enter your phone number',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        CustomTextField(
                          hintText: AppStrings.passwordHint,
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: _validatePassword,
                        ),
                      ],
                    ),
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
                
                // Or divider
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.defaultPadding),
                
                // Google Sign-in button
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: CustomButton(
                    text: 'Sign Up with Google',
                    icon: Icons.g_mobiledata,
                    isLoading: _isGoogleLoading,
                    onPressed: _signInWithGoogle,
                    color: Colors.white,
                    textColor: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSizes.largePadding),

                // Login Link
                FadeInUp(
                  delay: const Duration(milliseconds: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, RouteNames.login),
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
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

// Step 3: Role Selection Screen
class RoleSelectionScreen extends StatefulWidget {
  final firebase_auth.User user;
  final Map<String, dynamic> userData;
  final bool isGoogleSignIn;

  const RoleSelectionScreen({
    Key? key,
    required this.user,
    required this.userData,
    required this.isGoogleSignIn,
  }) : super(key: key);

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.patient;
  bool _isLoading = false;
  
  // Doctor-specific controllers
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _specialtyController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    _consultationFeeController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
  
  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  // Save user role and additional info
  Future<void> _saveUserRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update userData with role
      final updatedUserData = {
        ...widget.userData,
        'role': _selectedRole.toString().split('.').last,
      };
      
      // Save to users collection (for common data)
      await _firestore.collection('users').doc(widget.user.uid).set(updatedUserData);
      
      if (_selectedRole == UserRole.patient) {
        // Save to patients collection
        await _firestore.collection('patients').doc(widget.user.uid).set(updatedUserData);
        
        // Navigate to patient home
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, RouteNames.home);
      } else if (_selectedRole == UserRole.doctor) {
        // For doctors, we need additional information
        if (_specialtyController.text.isEmpty || 
            _experienceController.text.isEmpty || 
            _qualificationController.text.isEmpty || 
            _consultationFeeController.text.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all doctor information fields')),
          );
          return;
        }
        
        // Additional doctor data
        final doctorData = {
          ...updatedUserData,
          'specialty': _specialtyController.text,
          'experience': int.tryParse(_experienceController.text) ?? 0,
          'qualification': _qualificationController.text,
          'consultationFee': double.tryParse(_consultationFeeController.text) ?? 0,
          'clinicAddress': _clinicAddressController.text,
          'rating': 0.0,
          'isVerified': false, // Doctors need to be verified by admin
          'available': true, // Default availability
        };
        
        // Save to doctors collection
        await _firestore.collection('doctors').doc(widget.user.uid).set(doctorData);
        
        // Navigate to doctor home
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, RouteNames.doctorHome);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().split(']').last.trim()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Selection Header
              FadeInDown(
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSizes.smallPadding),
                    Text(
                      'How will you use BookMyDoc?',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.smallPadding),
                    Text(
                      'Select your role to personalize your experience',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.largePadding),

              // Role Selection Cards
              FadeInUp(
                child: Row(
                  children: [
                    Expanded(
                      child: _roleCard(
                        title: 'Patient',
                        description: 'Book appointments and consult with doctors',
                        icon: Icons.person,
                        isSelected: _selectedRole == UserRole.patient,
                        onTap: () => setState(() => _selectedRole = UserRole.patient),
                      ),
                    ),
                    const SizedBox(width: AppSizes.defaultPadding),
                    Expanded(
                      child: _roleCard(
                        title: 'Doctor',
                        description: 'Manage your practice and patients',
                        icon: Icons.medical_services,
                        isSelected: _selectedRole == UserRole.doctor,
                        onTap: () => setState(() => _selectedRole = UserRole.doctor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.largePadding),

              // Doctor-specific fields (shown only when doctor role is selected)
              if (_selectedRole == UserRole.doctor)
                FadeInUp(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                        child: Text(
                          'Doctor Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      CustomTextField(
                        hintText: 'Specialty (e.g., Cardiology)',
                        controller: _specialtyController,
                        prefixIcon: Icons.local_hospital,
                        validator: _validateRequired,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomTextField(
                        hintText: 'Years of Experience',
                        controller: _experienceController,
                        prefixIcon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomTextField(
                        hintText: 'Qualifications (e.g., MBBS, MD)',
                        controller: _qualificationController,
                        prefixIcon: Icons.school,
                        validator: _validateRequired,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomTextField(
                        hintText: 'Consultation Fee',
                        controller: _consultationFeeController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      CustomTextField(
                        hintText: 'Clinic Address',
                        controller: _clinicAddressController,
                        prefixIcon: Icons.location_on,
                        validator: _validateRequired,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSizes.largePadding),

              // Continue Button
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _saveUserRole,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}