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

  /// ✅ FIX: Classificação correta baseada em diretrizes médicas
  /// Segue as diretrizes da American Heart Association e SBC
  String get category {
    try {
      // Crise hipertensiva - prioridade máxima
      if (systolic >= 180 || diastolic >= 120) {
        AppConstants.logWarning('Pressão $systolic/$diastolic - CRISE HIPERTENSIVA detectada');
        return 'crisis';
      }

      // Hipertensão estágio 2
      if (systolic >= 140 || diastolic >= 90) {
        AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: Hipertensão Estágio 2');
        return 'high_stage2';
      }

      // Hipertensão estágio 1
      if (systolic >= 130 || diastolic >= 80) {
        AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: Hipertensão Estágio 1');
        return 'high_stage1';
      }

      // Pressão elevada (apenas sistólica)
      if (systolic >= 120 && diastolic < 80) {
        AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: Elevada');
        return 'elevated';
      }

      // Pressão ótima
      if (systolic < 120 && diastolic < 80) {
        AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: Ótima');
        return 'optimal';
      }

      // Normal (não deveria chegar aqui, mas é um fallback)
      AppConstants.logInfo('Pressão $systolic/$diastolic classificada como: Normal');
      return 'normal';

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao determinar categoria da pressão', e, stackTrace);
      return 'high_stage2'; // Default para alta em caso de erro
    }
  }

  /// ✅ FIX: Nomes das categorias atualizados
  String get categoryName {
    const categories = {
      'optimal': 'Ótima',
      'normal': 'Normal',
      'elevated': 'Elevada',
      'high_stage1': 'Alta Estágio 1',
      'high_stage2': 'Alta Estágio 2',
      'crisis': 'Crise Hipertensiva',
    };

    return categories[category] ?? 'Alta Estágio 2';
  }

  /// ✅ FIX: Cores das categorias atualizadas
  Color get categoryColor {
    const colors = {
      'optimal': Colors.green,
      'normal': Colors.blue,
      'elevated': Colors.orange,
      'high_stage1': Colors.deepOrange,
      'high_stage2': Colors.red,
      'crisis': Colors.purple,
    };

    return colors[category] ?? Colors.red;
  }

  /// ✅ FIX: Melhorar sistema de alertas médicos
  List<String> get medicalAlerts {
    final alerts = <String>[];

    // Alertas por categoria
    switch (category) {
      case 'crisis':
        alerts.add('⚠️ ATENÇÃO: Procure atendimento médico IMEDIATAMENTE');
        alerts.add('Valores indicam possível emergência hipertensiva');
        break;
      case 'high_stage2':
        alerts.add('⚠️ Pressão muito alta - consulte seu médico');
        alerts.add('Considere verificar novamente em 5 minutos');
        break;
      case 'high_stage1':
        alerts.add('⚠️ Pressão alta - monitoramento necessário');
        break;
      case 'elevated':
        alerts.add('💡 Pressão elevada - mudanças no estilo de vida podem ajudar');
        break;
    }

    // Alertas específicos para frequência cardíaca
    if (heartRate > 100) {
      alerts.add('❤️ Frequência cardíaca acelerada (taquicardia)');
    } else if (heartRate < 60) {
      alerts.add('❤️ Frequência cardíaca baixa (bradicardia)');
    }

    // Alerta para diferença de pulso
    final pulsePressure = systolic - diastolic;
    if (pulsePressure > 60) {
      alerts.add('📊 Pressão de pulso elevada (diferença entre sistólica e diastólica)');
    } else if (pulsePressure < 30) {
      alerts.add('📊 Pressão de pulso baixa');
    }

    return alerts;
  }

  /// ✅ FIX: Validações médicas mais rigorosas
  List<String> get validationErrors {
    final errors = <String>[];

    // Validações básicas de range
    if (systolic < AppConstants.minSystolic || systolic > AppConstants.maxSystolic) {
      errors.add('Sistólica fora da faixa válida (${AppConstants.minSystolic}-${AppConstants.maxSystolic})');
    }

    if (diastolic < AppConstants.minDiastolic || diastolic > AppConstants.maxDiastolic) {
      errors.add('Diastólica fora da faixa válida (${AppConstants.minDiastolic}-${AppConstants.maxDiastolic})');
    }

    if (heartRate < AppConstants.minHeartRate || heartRate > AppConstants.maxHeartRate) {
      errors.add('Frequência cardíaca fora da faixa válida (${AppConstants.minHeartRate}-${AppConstants.maxHeartRate})');
    }

    // ✅ FIX: Validação médica crítica
    if (systolic <= diastolic) {
      errors.add('ERRO CRÍTICO: Pressão sistólica deve ser maior que diastólica');
    }

    // Validação de data
    if (measuredAt.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      errors.add('Data/hora da medição não pode ser no futuro');
    }

    // Validação de idade da medição
    final daysSinceMeasurement = DateTime.now().difference(measuredAt).inDays;
    if (daysSinceMeasurement > 365) {
      errors.add('Medição muito antiga (mais de 1 ano)');
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

  /// ✅ FIX: Método para verificar se precisa de atenção médica
  bool get needsUrgentAttention {
    return category == 'crisis' ||
        (systolic >= 180 || diastolic >= 120) ||
        heartRate > 150 ||
        heartRate < 40;
  }

  /// ✅ FIX: Formatação de data mais robusta
  String get formattedDate {
    try {
      return '${measuredAt.day.toString().padLeft(2, '0')}/${measuredAt.month.toString().padLeft(2, '0')}/${measuredAt.year}';
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao formatar data', e, stackTrace);
      return 'Data inválida';
    }
  }

  /// ✅ FIX: Formatação de hora mais robusta
  String get formattedTime {
    try {
      return '${measuredAt.hour.toString().padLeft(2, '0')}:${measuredAt.minute.toString().padLeft(2, '0')}';
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao formatar hora', e, stackTrace);
      return 'Hora inválida';
    }
  }

  /// ✅ FIX: Formatação de data/hora mais completa
  String get formattedDateTime {
    return '$formattedDate às $formattedTime';
  }

  /// ✅ FIX: Método para obter descrição completa
  String get summary {
    final alerts = medicalAlerts;
    final alertText = alerts.isNotEmpty ? ' - ${alerts.first}' : '';
    return '$systolic/$diastolic mmHg, $heartRate bpm ($categoryName)$alertText';
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