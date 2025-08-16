import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Modelo de dados para medições de pressão arterial
class MeasurementModel {
  final int? id;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final DateTime measuredAt;
  final DateTime createdAt;
  final String? notes; // Campo opcional para anotações

  const MeasurementModel({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.measuredAt,
    required this.createdAt,
    this.notes,
  });

  /// Construtor para criar medição vazia
  MeasurementModel.empty()
      : id = null,
        systolic = 120,
        diastolic = 80,
        heartRate = 72,
        measuredAt = DateTime.now(),
        createdAt = DateTime.now(),
        notes = null;

  /// Retorna a categoria da pressão (normal, elevada, alta)
  String get category {
    try {
      for (final entry in AppConstants.pressureCategories.entries) {
        final data = entry.value;
        if (systolic <= data['systolicMax'] && diastolic <= data['diastolicMax']) {
          AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: ${data['name']}');
          return entry.key;
        }
      }

      AppConstants.logWarning('Pressão $systolic/$diastolic não se encaixou em nenhuma categoria, assumindo "alta"');
      return 'high';
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao determinar categoria da pressão', e, stackTrace);
      return 'high'; // Default para alta em caso de erro
    }
  }

  /// Retorna o nome da categoria da pressão
  String get categoryName {
    return AppConstants.pressureCategories[category]?['name'] ?? 'Alta';
  }

  /// Retorna a cor da categoria da pressão
  Color get categoryColor {
    return AppConstants.pressureCategories[category]?['color'] ?? Colors.red;
  }

  /// Valida se os valores da medição estão dentro dos limites esperados
  List<String> get validationErrors {
    final errors = <String>[];

    if (systolic < AppConstants.minSystolic || systolic > AppConstants.maxSystolic) {
      errors.add('Sistólica fora da faixa normal (${AppConstants.minSystolic}-${AppConstants.maxSystolic})');
    }

    if (diastolic < AppConstants.minDiastolic || diastolic > AppConstants.maxDiastolic) {
      errors.add('Diastólica fora da faixa normal (${AppConstants.minDiastolic}-${AppConstants.maxDiastolic})');
    }

    if (heartRate < AppConstants.minHeartRate || heartRate > AppConstants.maxHeartRate) {
      errors.add('Frequência cardíaca fora da faixa normal (${AppConstants.minHeartRate}-${AppConstants.maxHeartRate})');
    }

    if (measuredAt.isAfter(DateTime.now().add(Duration(hours: 1)))) {
      errors.add('Data/hora da medição não pode ser no futuro');
    }

    if (errors.isNotEmpty) {
      AppConstants.logWarning('Medição com erros de validação: ${errors.join(', ')}');
    } else {
      AppConstants.logInfo('Medição $systolic/$diastolic-${heartRate}bpm validada com sucesso');
    }

    return errors;
  }

  /// Verifica se a medição é válida
  bool get isValid => validationErrors.isEmpty;

  /// Retorna a data formatada (DD/MM/YYYY)
  String get formattedDate {
    try {
      return '${measuredAt.day.toString().padLeft(2, '0')}/${measuredAt.month.toString().padLeft(2, '0')}/${measuredAt.year}';
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao formatar data', e, stackTrace);
      return '';
    }
  }

  /// Retorna a hora formatada (HH:MM)
  String get formattedTime {
    try {
      return '${measuredAt.hour.toString().padLeft(2, '0')}:${measuredAt.minute.toString().padLeft(2, '0')}';
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao formatar hora', e, stackTrace);
      return '';
    }
  }

  /// Converte de Map para MeasurementModel (vindo do database)
  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    try {
      AppConstants.logDatabase('fromMap', 'measurements', 'Converting map to MeasurementModel');

      return MeasurementModel(
        id: map['id'] as int?,
        systolic: map['systolic'] as int? ?? 120,
        diastolic: map['diastolic'] as int? ?? 80,
        heartRate: map['heart_rate'] as int? ?? 72,
        measuredAt: DateTime.parse(map['measured_at'] as String? ?? DateTime.now().toIso8601String()),
        createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
        notes: map['notes'] as String?,
      );
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao converter Map para MeasurementModel', e, stackTrace);
      rethrow;
    }
  }

  /// Converte de MeasurementModel para Map (para salvar no database)
  Map<String, dynamic> toMap() {
    try {
      final map = {
        'systolic': systolic,
        'diastolic': diastolic,
        'heart_rate': heartRate,
        'measured_at': measuredAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'notes': notes,
      };

      if (id != null) {
        map['id'] = id!;
      }

      AppConstants.logDatabase('toMap', 'measurements', 'Converting MeasurementModel to map');
      return map;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao converter MeasurementModel para Map', e, stackTrace);
      rethrow;
    }
  }

  /// Cria uma cópia da medição com campos atualizados
  MeasurementModel copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? heartRate,
    DateTime? measuredAt,
    DateTime? createdAt,
    String? notes,
  }) {
    AppConstants.logInfo('Criando cópia da medição com alterações');

    return MeasurementModel(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  /// Converte para JSON string (útil para debug)
  @override
  String toString() {
    return 'MeasurementModel(id: $id, systolic: $systolic, diastolic: $diastolic, heartRate: $heartRate, measuredAt: $measuredAt, category: $categoryName, notes: $notes)';
  }

  /// Compara duas medições
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeasurementModel &&
        other.id == id &&
        other.systolic == systolic &&
        other.diastolic == diastolic &&
        other.heartRate == heartRate &&
        other.measuredAt == measuredAt &&
        other.createdAt == createdAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    systolic.hashCode ^
    diastolic.hashCode ^
    heartRate.hashCode ^
    measuredAt.hashCode ^
    createdAt.hashCode ^
    notes.hashCode;
  }
}