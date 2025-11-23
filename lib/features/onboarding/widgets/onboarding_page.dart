import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppConstants.logoGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['icon'],
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data['title'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            data['content'],
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}