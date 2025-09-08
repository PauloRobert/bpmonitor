import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_entity.freezed.dart';

@freezed
class MeasurementEntity with _$MeasurementEntity {
  const factory MeasurementEntity({
    required String id,
    required int systolic,
    required int diastolic,
    required int heartRate,
    required DateTime measuredAt,
    required DateTime createdAt,
    String? notes,
  }) = _MeasurementEntity;

  const MeasurementEntity._();

  String get category => _calculateCategory();

  String _calculateCategory() {
    // Lógica básica - será movida para um use case
    if (systolic >= 180 || diastolic >= 120) return 'crisis';
    if (systolic >= 140 || diastolic >= 90) return 'high_stage2';
    if (systolic >= 130 || diastolic >= 80) return 'high_stage1';
    if (systolic >= 120 && diastolic < 80) return 'elevated';
    if (systolic < 120 && diastolic < 80) return 'optimal';
    return 'normal';
  }
}