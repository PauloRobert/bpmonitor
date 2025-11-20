import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class GenderSelector extends StatelessWidget {
  final String? value;                    // agora aceita null
  final Function(String) onChanged;

  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wc, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Sexo *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _option('M', Icons.male)),
              const SizedBox(width: 12),
              Expanded(child: _option('F', Icons.female)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(String gender, IconData icon) {
    final isSelected = value != null && gender == value;    // CORREÇÃO
    final name = AppConstants.genderOptions[gender]!;

    return InkWell(
      onTap: () => onChanged(gender),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}