import 'package:bp_monitor/domain/entities/measurement_entity.dart';

class MeasurementModel {
  final String id;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final DateTime measuredAt;
  final DateTime createdAt;
  final String? notes;
  final String userId;

  MeasurementModel({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.measuredAt,
    required this.createdAt,
    this.notes,
    required this.userId,
  });

  factory MeasurementModel.fromEntity(MeasurementEntity entity, String userId) {
    return MeasurementModel(
      id: entity.id,
      systolic: entity.systolic,
      diastolic: entity.diastolic,
      heartRate: entity.heartRate,
      measuredAt: entity.measuredAt,
      createdAt: entity.createdAt,
      notes: entity.notes,
      userId: userId,
    );
  }

  MeasurementEntity toEntity() {
    return MeasurementEntity(
      id: id,
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      measuredAt: measuredAt,
      createdAt: createdAt,
      notes: notes,
    );
  }

  factory MeasurementModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MeasurementModel(
      id: id,
      systolic: data['systolic'] ?? 0,
      diastolic: data['diastolic'] ?? 0,
      heartRate: data['heartRate'] ?? 0,
      measuredAt: DateTime.parse(data['measuredAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      notes: data['notes'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'heartRate': heartRate,
      'measuredAt': measuredAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'userId': userId,
    };
  }
}