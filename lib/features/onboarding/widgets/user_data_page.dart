import 'package:flutter/material.dart';
import '../onboarding_controller.dart';
import '../formatters/date_mask_formatter.dart';
import 'gender_selector.dart';
import 'bmi_preview.dart';

class UserDataPage extends StatelessWidget {
  final OnboardingController controller;

  const UserDataPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          TextField(
            controller: controller.name,
            decoration: const InputDecoration(
              labelText: "Nome completo *",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: controller.birthDate,
            decoration: const InputDecoration(
              labelText: "Data de nascimento *",
              prefixIcon: Icon(Icons.cake),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [DateMaskFormatter()],
            onTap: () => controller.pickBirthDate(context),
            readOnly: true, // força usar somente o DatePicker (opcional)
          ),

          ValueListenableBuilder<String?>(
            valueListenable: controller.gender,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.birthDate.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text("Idade: ${controller.age} anos"),
                    ),
                  const SizedBox(height: 20),
                  GenderSelector(
                    value: value, // reativo via ValueListenableBuilder
                    onChanged: (g) {
                      // atualiza o ValueNotifier — isso dispara rebuild do ValueListenableBuilder
                      controller.gender.value = g;
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          TextField(
            controller: controller.weight,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Peso (kg) *",
              prefixIcon: Icon(Icons.monitor_weight),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),
          TextField(
            controller: controller.height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Altura (m) *",
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),
          if (controller.weight.text.isNotEmpty &&
              controller.height.text.isNotEmpty)
            BMIPreview(controller: controller),
        ],
      ),
    );
  }
}