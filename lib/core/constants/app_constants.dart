import 'package:flutter/material.dart';

class AppConstants {
  // Cores
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFDC2626);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Firebase
  static const String remoteConfigDefaultsPath = 'assets/remote_config_defaults.json';

  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String homeRoute = '/home';
  static const String authRoute = '/auth';
}