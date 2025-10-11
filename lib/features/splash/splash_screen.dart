import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Remove a status bar para uma transição mais limpa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // Inicia a navegação imediatamente
    _navigateAfterMinimalDelay();
  }

  Future<void> _navigateAfterMinimalDelay() async {
    // Tempo mínimo para evitar flash, mas mantém a performance
    const minDisplayTime = Duration(milliseconds: 300);

    // Inicia as operações em paralelo
    final futures = await Future.wait([
      Future.delayed(minDisplayTime),
      _checkOnboardingStatus(),
    ]);

    final route = futures[1] as String;

    if (mounted) {
      // Restaura a UI do sistema antes de navegar
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  Future<String> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
      return isComplete ? AppRouter.main : AppRouter.onboarding;
    } catch (e) {
      return AppRouter.onboarding;
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

  @override
  void dispose() {
    // Garante que a UI do sistema seja restaurada
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}