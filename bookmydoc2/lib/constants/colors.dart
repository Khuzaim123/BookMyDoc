import 'package:flutter/material.dart';

class AppColors {
  // Primary and Accent Colors
  static const Color primary = Color(0xFF2196F3); // Material Blue
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color accent = Color(0xFF03A9F4);

  // Background and Surface Colors
  static const Color background = Colors.white;
  static const Color cardBackground = Color(
    0xFFF5F5F5,
  ); // Light grey for card backgrounds
  static const Color shadowColor = Colors.black12; // Subtle shadow

  // Text Colors
  static const Color textPrimary = Color(
    0xFF212121,
  ); // Dark Grey for primary text
  static const Color textLight = Color(
    0xFF757575,
  ); // Medium Grey for secondary/light text
  static const Color textSecondary = Color(
    0xFF757575,
  ); // Lighter grey for secondary text
  static const Color textHint = Color(0xFFB0BEC5); // Hint text color

  // Status Colors
  static const Color success = Color(
    0xFF4CAF50,
  ); // Green for success (e.g., booked)
  static const Color warning = Color(0xFFFF9800); // Orange for warnings
  static const Color error = Color(0xFFF44336); // Material Red for errors
}
