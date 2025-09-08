// core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/core/di/injection_container.dart';

class AppTheme {
  final RemoteConfigService _remoteConfig;

  AppTheme({required RemoteConfigService remoteConfig})
      : _remoteConfig = remoteConfig;

  // Cores primárias do tema
  Color get primaryColor => _remoteConfig.getColor('primary_color') ?? AppConstants.primaryColor;
  Color get secondaryColor => _remoteConfig.getColor('secondary_color') ?? AppConstants.secondaryColor;
  Color get backgroundColor => _remoteConfig.getColor('background_color') ?? AppConstants.backgroundColor;
  Color get cardColor => _remoteConfig.getColor('card_color') ?? AppConstants.cardColor;
  Color get textPrimaryColor => _remoteConfig.getColor('text_primary_color') ?? AppConstants.textPrimary;
  Color get textSecondaryColor => _remoteConfig.getColor('text_secondary_color') ?? AppConstants.textSecondary;

  // Cores por categoria de pressão
  Color get optimalColor => _remoteConfig.getColor('optimal_color') ?? const Color(0xFF10B981);
  Color get normalColor => _remoteConfig.getColor('normal_color') ?? const Color(0xFF3B82F6);
  Color get elevatedColor => _remoteConfig.getColor('elevated_color') ?? const Color(0xFFF59E0B);
  Color get highStage1Color => _remoteConfig.getColor('high_stage1_color') ?? const Color(0xFFEF4444);
  Color get highStage2Color => _remoteConfig.getColor('high_stage2_color') ?? const Color(0xFFDC2626);
  Color get crisisColor => _remoteConfig.getColor('crisis_color') ?? const Color(0xFF7C3AED);

  // Gradientes
  LinearGradient get splashGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryColor,
      primaryColor.withOpacity(0.8),
      secondaryColor,
    ],
  );

  LinearGradient get logoGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondaryColor,
      primaryColor,
    ],
  );

  // Configurações do tema
  double get borderRadius => _remoteConfig.getDouble('border_radius') ?? AppConstants.borderRadius;
  double get cardPadding => _remoteConfig.getDouble('card_padding') ?? AppConstants.cardPadding;

  // Gerar ThemeData para o aplicativo
  ThemeData getThemeData(BuildContext context) {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: secondaryColor),
        ),
        contentPadding: EdgeInsets.all(cardPadding),
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondaryColor,
        ),
      ),
    );
  }

  // Método para obter cor baseada na categoria de pressão
  Color getCategoryColor(String category) {
    switch (category) {
      case 'optimal': return optimalColor;
      case 'normal': return normalColor;
      case 'elevated': return elevatedColor;
      case 'high_stage1': return highStage1Color;
      case 'high_stage2': return highStage2Color;
      case 'crisis': return crisisColor;
      default: return normalColor;
    }
  }
}