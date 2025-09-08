import 'package:flutter/material.dart';
import 'package:bp_monitor/presentation/features/splash/splash_screen.dart';
import 'package:bp_monitor/presentation/features/auth/auth_screen.dart';
import 'package:bp_monitor/presentation/features/onboarding/onboarding_screen.dart';
import 'package:bp_monitor/presentation/features/home/home_screen.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppConstants.onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case AppConstants.authRoute:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}