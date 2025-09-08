// core/constants/app_constants.dart
import 'package:flutter/material.dart';

/// Constantes globais do aplicativo BP Monitor
class AppConstants {
  // Informações do App
  static const String version = '1.0.0';

  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String authRoute = '/auth';
  static const String homeRoute = '/home';
  static const String addMeasurementRoute = '/add_measurement';
  static const String editMeasurementRoute = '/edit_measurement';
  static const String historyRoute = '/history';
  static const String statisticsRoute = '/statistics';
  static const String profileRoute = '/profile';

  // SharedPreferences Keys
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeKey = 'theme_mode';
  static const String syncEnabledKey = 'sync_enabled';
  static const String lastSyncKey = 'last_sync';

  // Hive Box Names
  static const String measurementsBoxName = 'measurements';
  static const String syncFlagsBoxName = 'sync_flags';
  static const String deletionFlagsBoxName = 'deletion_flags';
  static const String settingsBoxName = 'settings';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String measurementsCollection = 'measurements';

  // Paginação
  static const int defaultPageSize = 20;
  static const int maxItemsInMemory = 100;

  // Default Colors (substituídas pelo RemoteConfig quando disponível)
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFDC2626);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Gradientes
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFFDC2626),
    ],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),
      Color(0xFF2563EB),
    ],
  );

  // Tamanhos
  static const double borderRadius = 12.0;
  static const double cardPadding = 16.0;
  static const double iconSize = 24.0;
  static const double headerFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // Animações
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(milliseconds: 1500);

  // Remote Config Keys
  // Estas constantes são usadas para definir nomes de chaves do Remote Config
  // para evitar strings hardcoded espalhadas pelo código
  static const String remoteConfigKeyPrimaryColor = 'primary_color';
  static const String remoteConfigKeySecondaryColor = 'secondary_color';
  static const String remoteConfigKeySyncInterval = 'sync_interval_minutes';
  static const String remoteConfigKeyEnableReports = 'enable_reports';
  static const String remoteConfigKeyEnableCharts = 'enable_charts';
}