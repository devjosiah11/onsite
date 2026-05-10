import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF6B21A8);  // Purple
  static const Color secondaryBlue = Color(0xFF9333EA);  // Purple shade
  static const Color darkBlue = Color(0xFF581C87);  // Dark purple
  
  // Accent colors
  static const Color lightCyan = Color(0xFFE9D5FF);  // Light purple
  static const Color softCyan = Color(0xFFF3E8FF);  // Soft purple
  
  // Sentiment colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFFA000);
  
  // Neutral colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1C2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],  // Purple gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFFE9D5FF), Color(0xFFC084FC)],  // Light to medium purple gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
