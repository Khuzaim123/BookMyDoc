import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/user.dart';
import 'package:bookmydoc2/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email & Password login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        
        // Sign in with email and password
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (userCredential.user != null) {
          // Get user data including role from Firestore
          await _navigateBasedOnUserRole(userCredential.user!.uid);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        
        // Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString().split(']').last.trim()}')),
        );
      }
    }
  }

  // Google Sign In
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isGoogleLoading = true);
      
      // Initialize Google Sign In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; // User canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if this user already exists in Firestore
        final docSnapshot = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!docSnapshot.exists) {
          // First time Google sign-in, need to set role (redirect to role selection)
          setState(() => _isGoogleLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign up first to select your role')),
          );
          
          Navigator.pushNamed(context, RouteNames.signUp);
          return;
        }
        
        // User exists, navigate based on role
        await _navigateBasedOnUserRole(userCredential.user!.uid);
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: ${e.toString().split(']').last.trim()}')),
      );
    }
  }

  // Navigate based on user role fetched from Firestore
  Future<void> _navigateBasedOnUserRole(String userId) async {
    try {
      // Get user data from Firestore
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        final roleStr = userData['role'] as String;
        
        setState(() => _isLoading = false);
        setState(() => _isGoogleLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${userData['name']}')),
        );
        
        // Navigate based on role
        if (roleStr == 'patient') {
          Navigator.pushNamed(context, RouteNames.home);
        } else if (roleStr == 'doctor') {
          Navigator.pushNamed(context, RouteNames.doctorHome);
        } else if (roleStr == 'admin') {
          // Admin dashboard (to be implemented)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin dashboard coming soon!')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        setState(() => _isGoogleLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User account not found')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      setState(() => _isGoogleLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: ${e.toString().split(']').last.trim()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // App Logo/Title
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Text(
                      'BookMyDoc',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Subtitle
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Text(
                      'Login to your account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Email Field
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Forgot Password Link
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, RouteNames.forgotPassword);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Login Button
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Or divider
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Google Sign In Button
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: CustomButton(
                    text: 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    onPressed: _signInWithGoogle,
                    color: Colors.white,
                    textColor: Colors.black87,
                    isLoading: _isGoogleLoading,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up Link
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, RouteNames.signUp);
                        },
                        child: Text(
                          'Sign Up',
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
