import 'package:flutter/material.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/presentation/features/auth/auth_screen.dart';
import 'package:bp_monitor/presentation/features/onboarding/onboarding_screen.dart';
import 'package:bp_monitor/core/di/injection_container.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authRepository = sl<AuthRepository>();
    final isAuthenticated = await authRepository.isAuthenticated();

    if (isAuthenticated) {
      // Navegar para a Home se autenticado
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      }
    } else {
      // Verificar se já concluiu onboarding
      final sharedPreferences = sl<SharedPreferences>();
      final completedOnboarding = sharedPreferences.getBool('onboarding_complete') ?? false;

      if (completedOnboarding) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppConstants.authRoute);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              Color(0xFF1D4ED8),
              AppConstants.secondaryColor,
            ],
          ),
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
                'BP Monitor',
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