import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hospital Icon with fade and bounce animation
            FadeInDown(
              duration: const Duration(milliseconds: 1500),
              child: BounceInDown(
                duration: const Duration(milliseconds: 1500),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App Name with fade animation
            FadeIn(
              duration: const Duration(milliseconds: 1500),
              delay: const Duration(milliseconds: 500),
              child: Text(
                'BookMyDoc',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tagline with fade animation
            FadeIn(
              duration: const Duration(milliseconds: 1500),
              delay: const Duration(milliseconds: 1000),
              child: Text(
                'Your Health, Our Priority',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
