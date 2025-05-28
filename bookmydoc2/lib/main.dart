import 'package:bookmydoc2/firebase_options.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookMyDoc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      onGenerateRoute: generateRoute,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          // User is signed in, check their role
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final role = userData['role'] as String;

            if (!mounted) return;

            // Navigate based on role
            if (role == 'patient') {
              Navigator.pushReplacementNamed(context, RouteNames.home);
            } else if (role == 'doctor') {
              Navigator.pushReplacementNamed(context, RouteNames.doctorHome);
            } else if (role == 'admin') {
              // Handle admin role if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin dashboard coming soon!')),
              );
            }
          }
        } else {
          // No user is signed in
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, RouteNames.login);
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking auth state: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Center(child: Text('Loading...')),
    );
  }
}
