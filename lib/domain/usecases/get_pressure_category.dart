import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/core/di/injection_container.dart';

class GetPressureCategory {
  final RemoteConfigService remoteConfig;
  final AppStrings strings;

  GetPressureCategory({
    required this.remoteConfig,
    required this.strings,
  });

  // Retorna categoria da pressão baseada nos valores e configurações remotas
  String call({required int systolic, required int diastolic}) {
    // Valores da configuração remota
    final optimalSystolicMax = remoteConfig.getInt('optimal_systolic_max');
    final optimalDiastolicMax = remoteConfig.getInt('optimal_diastolic_max');
    final normalSystolicMax = remoteConfig.getInt('normal_systolic_max');
    final normalDiastolicMax = remoteConfig.getInt('normal_diastolic_max');
    final elevatedSystolicMax = remoteConfig.getInt('elevated_systolic_max');
    final elevatedDiastolicMax = remoteConfig.getInt('elevated_diastolic_max');
    final highStage1SystolicMax = remoteConfig.getInt('high_stage1_systolic_max');
    final highStage1DiastolicMax = remoteConfig.getInt('high_stage1_diastolic_max');
    final highStage2SystolicMax = remoteConfig.getInt('high_stage2_systolic_max');
    final highStage2DiastolicMax = remoteConfig.getInt('high_stage2_diastolic_max');

    // Crise hipertensiva
    if (systolic >= 180 || diastolic >= 120) {
      return 'crisis';
    }

    // Hipertensão estágio 2
    if (systolic > highStage1SystolicMax || diastolic > highStage1DiastolicMax) {
      return 'high_stage2';
    }

    // Hipertensão estágio 1
    if (systolic >= elevatedSystolicMax || diastolic >= elevatedDiastolicMax) {
      return 'high_stage1';
    }

    // Pressão elevada (apenas sistólica)
    if (systolic >= optimalSystolicMax && diastolic < optimalDiastolicMax) {
      return 'elevated';
    }

    // Pressão ótima
    if (systolic < optimalSystolicMax && diastolic < optimalDiastolicMax) {
      return 'optimal';
    }

    // Normal
    return 'normal';
  }

  // Retorna o nome da categoria
  String getName(String category) {
    switch (category) {
      case 'optimal': return strings.optimalCategory;
      case 'normal': return strings.normalCategory;
      case 'elevated': return strings.elevatedCategory;
      case 'high_stage1': return strings.highStage1Category;
      case 'high_stage2': return strings.highStage2Category;
      case 'crisis': return strings.crisisCategory;
      default: return strings.normalCategory;
    }
  }

  // Retorna a cor da categoria
  Color getColor(String category) {
    switch (category) {
      case 'optimal': return remoteConfig.getColor('optimal_color');
      case 'normal': return remoteConfig.getColor('normal_color');
      case 'elevated': return remoteConfig.getColor('elevated_color');
      case 'high_stage1': return remoteConfig.getColor('high_stage1_color');
      case 'high_stage2': return remoteConfig.getColor('high_stage2_color');
      case 'crisis': return remoteConfig.getColor('crisis_color');
      default: return remoteConfig.getColor('normal_color');
    }
  }
}