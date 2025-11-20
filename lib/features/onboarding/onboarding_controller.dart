import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import './utils/fixed_date_picker.dart';

class OnboardingController {
  final name = TextEditingController();
  final birthDate = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();

  final db = DatabaseService.instance;
  bool isLoading = false;

  /// Tornamos reativo com ValueNotifier para atualizar a UI quando mudar.
  final ValueNotifier<String?> gender = ValueNotifier<String?>(null);

  void dispose() {
    name.dispose();
    birthDate.dispose();
    weight.dispose();
    height.dispose();
    gender.dispose();
  }

  int get age {
    if (birthDate.text.isEmpty) return 0;
    try {
      final parts = birthDate.text.split('/');
      final dt = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      final now = DateTime.now();
      int a = now.year - dt.year;
      if (now.month < dt.month ||
          (now.month == dt.month && now.day < dt.day)) {
        a--;
      }
      return a;
    } catch (_) {
      return 0;
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showFixedDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthDate.text =
      '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      // opcional: notificar listeners caso alguém precise da mudança da birthDate
    }
  }

  String? validateAll() {
    if (name.text.trim().isEmpty) {
      return AppConstants.validationNameError;
    }

    if (birthDate.text.isEmpty) {
      return AppConstants.validationBirthDateError;
    }

    if (age < 10) {
      return AppConstants.validationAgeError;
    }

    if (gender.value == null) {
      return "Selecione o sexo.";
    }

    final w = double.tryParse(weight.text.replaceAll(',', '.'));
    final h = double.tryParse(height.text.replaceAll(',', '.'));

    if (w == null ||
        w < AppConstants.minWeight ||
        w > AppConstants.maxWeight) {
      return AppConstants.validationWeightError;
    }

    if (h == null ||
        h < AppConstants.minHeight ||
        h > AppConstants.maxHeight) {
      return AppConstants.validationHeightError;
    }

    return null;
  }

  Future<bool> save() async {
    final error = validateAll();
    if (error != null) return false;

    isLoading = true;

    final w = double.parse(weight.text.replaceAll(',', '.'));
    final h = double.parse(height.text.replaceAll(',', '.'));

    final user = UserModel(
      name: name.text.trim(),
      birthDate: birthDate.text,
      gender: gender.value!, // garantido não-nulo por validateAll
      weight: w,
      height: h,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!user.isValid) {
      isLoading = false;
      return false;
    }

    await db.insertUser(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);

    isLoading = false;
    return true;
  }
}