import 'package:equatable/equatable.dart';

class MeasurementEntity extends Equatable {
  final String id;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final DateTime measuredAt;
  final DateTime createdAt;
  final String? notes;

  const MeasurementEntity({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.measuredAt,
    required this.createdAt,
    this.notes,
  });

  MeasurementEntity copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    int? heartRate,
    DateTime? measuredAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return MeasurementEntity(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

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

  @override
  List<Object?> get props => [
    id,
    systolic,
    diastolic,
    heartRate,
    measuredAt,
    createdAt,
    notes,
  ];
}