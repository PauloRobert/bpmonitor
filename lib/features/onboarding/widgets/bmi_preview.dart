import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../onboarding_controller.dart';

class BMIPreview extends StatelessWidget {
  final OnboardingController controller;

  const BMIPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(controller.weight.text.replaceAll(',', '.'));
    final height = double.tryParse(controller.height.text.replaceAll(',', '.'));

    if (weight == null || height == null || height <= 0) {
      return const SizedBox.shrink();
    }

    final bmi = AppConstants.calculateBMI(weight, height);
    final category = AppConstants.getBMICategory(bmi);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 20, color: AppConstants.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu IMC',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                Text(
                  '${bmi.toStringAsFixed(1)} - $category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}