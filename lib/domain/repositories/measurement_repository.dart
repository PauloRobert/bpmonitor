import 'package:dartz/dartz.dart';
import 'package:bp_monitor/core/error/failures.dart';
import 'package:bp_monitor/domain/entities/measurement_entity.dart';

abstract class MeasurementRepository {
  /// Obtém todas as medições
  Future<Either<Failure, List<MeasurementEntity>>> getMeasurements();

  /// Obtém medições recentes com limite
  Future<Either<Failure, List<MeasurementEntity>>> getRecentMeasurements({int limit = 10});

  /// Salva uma nova medição
  Future<Either<Failure, MeasurementEntity>> saveMeasurement(MeasurementEntity measurement);

  /// Atualiza uma medição existente
  Future<Either<Failure, MeasurementEntity>> updateMeasurement(MeasurementEntity measurement);

  /// Remove uma medição
  Future<Either<Failure, bool>> deleteMeasurement(String id);
}