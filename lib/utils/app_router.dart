import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../shared/widgets/main_navigation.dart';

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

  static Future<String> getInitialRoute() async {
    try {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUser();

      if (user == null) {
        return onboarding;
      }

      return main;
    } catch (e) {
      return onboarding;
    }
  }
}