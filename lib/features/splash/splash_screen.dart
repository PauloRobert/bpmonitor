import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // CORREÇÃO: Operação mínima, sem animações
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Aguarda apenas 500ms para mostrar o logo
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Verificação rápida apenas de SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
      final route = isComplete ? AppRouter.main : AppRouter.onboarding;

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.splashGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}