import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final UserModel? user;
  final String greeting;

  const HomeHeader({
    super.key,
    required this.user,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final userName = user?.name ?? 'Usuário';
    final age = user?.age ?? 0;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            gradient: AppConstants.logoGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $userName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (age > 0)
                Text(
                  '$age anos',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}