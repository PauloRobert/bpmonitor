import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../shared/widgets/main_navigation.dart';
import '../core/constants/app_constants.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  // CORREÇÃO: Método mais rápido, apenas SharedPreferences
  static Future<String> getInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete = prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
      return isOnboardingComplete ? main : onboarding;
    } catch (e) {
      return onboarding;
    }
  }
}