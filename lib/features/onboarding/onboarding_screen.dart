import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../onboarding/onboarding_controller.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/user_data_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = OnboardingController();
  final pageController = PageController();

  int current = 0;

  @override
  void dispose() {
    pageController.dispose();
    controller.dispose();
    super.dispose();
  }

  void next() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void prev() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = current == AppConstants.onboardingData.length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: AppConstants.onboardingData.length + 1,
                onPageChanged: (i) => setState(() => current = i),
                itemBuilder: (context, i) {
                  if (i < AppConstants.onboardingData.length) {
                    return OnboardingPage(data: AppConstants.onboardingData[i]);
                  }
                  return UserDataPage(controller: controller);
                },
              ),
            ),
            _bottom(isLast),
          ],
        ),
      ),
    );
  }

  Widget _bottom(bool isLast) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (current > 0)
            TextButton(onPressed: prev, child: const Text("Anterior")),
          const Spacer(),
          isLast
              ? ElevatedButton(
            onPressed: () async {
              final ok = await controller.save();
              if (ok && mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dados inválidos")),
                );
              }
            },
            child: const Text("Começar"),
          )
              : ElevatedButton(onPressed: next, child: const Text("Próximo")),
        ],
      ),
    );
  }
}