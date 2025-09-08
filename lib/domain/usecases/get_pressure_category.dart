import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:flutter/material.dart';

class GetPressureCategory {
  final RemoteConfigService remoteConfig;

  GetPressureCategory({required this.remoteConfig});

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
      case 'optimal': return 'Ótima';
      case 'normal': return 'Normal';
      case 'elevated': return 'Elevada';
      case 'high_stage1': return 'Alta Estágio 1';
      case 'high_stage2': return 'Alta Estágio 2';
      case 'crisis': return 'Crise Hipertensiva';
      default: return 'Normal';
    }
  }

  // Retorna a cor da categoria
  Color getColor(String category) {
    switch (category) {
      case 'optimal': return const Color(0xFF10B981); // Verde
      case 'normal': return const Color(0xFF3B82F6); // Azul
      case 'elevated': return const Color(0xFFF59E0B); // Laranja
      case 'high_stage1': return const Color(0xFFEF4444); // Vermelho claro
      case 'high_stage2': return const Color(0xFFDC2626); // Vermelho escuro
      case 'crisis': return const Color(0xFF7C3AED); // Roxo
      default: return const Color(0xFF3B82F6); // Azul
    }
  }
}