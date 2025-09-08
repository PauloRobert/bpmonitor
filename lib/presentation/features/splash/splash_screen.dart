import 'package:flutter/material.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/core/di/injection_container.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppStrings _strings = sl<AppStrings>();

  // ...resto do código permanece igual

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                _strings.appName,  // <-- Usando AppStrings
                style: const TextStyle(
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