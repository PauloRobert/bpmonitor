// data/datasources/local/measurement_local_datasource.dart
import 'package:hive/hive.dart';
import 'package:bp_monitor/core/error/exceptions.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/data/models/measurement_model.dart';

abstract class MeasurementLocalDataSource {
  /// Obtém todas as medições do cache local
  Future<List<MeasurementModel>> getLastMeasurements({int limit = 100});

  /// Salva uma medição no cache local
  Future<void> cacheMeasurement(MeasurementModel measurement);

  /// Salva várias medições no cache local
  Future<void> cacheMeasurements(List<MeasurementModel> measurements);

  /// Atualiza uma medição no cache local
  Future<void> updateMeasurement(MeasurementModel measurement);

  /// Exclui uma medição do cache local
  Future<void> deleteMeasurement(String id);

  /// Marca uma medição para sincronização
  Future<void> markForSync(String id);

  /// Marca uma medição para exclusão na próxima sincronização
  Future<void> markForDeletion(String id);

  /// Obtém medições que precisam ser sincronizadas
  Future<List<MeasurementModel>> getPendingSyncMeasurements();

  /// Obtém IDs de medições que precisam ser excluídas
  Future<List<String>> getPendingDeletionIds();

  /// Remove marcação de sincronização
  Future<void> clearSyncFlag(String id);

  /// Remove marcação de exclusão
  Future<void> clearDeletionFlag(String id);
}

class MeasurementLocalDataSourceImpl implements MeasurementLocalDataSource {
  final Box<Map> measurementsBox;
  final Box<bool> syncFlagsBox;
  final Box<bool> deletionFlagsBox;
  final AppLogger logger;

  MeasurementLocalDataSourceImpl({
    required this.measurementsBox,
    required this.syncFlagsBox,
    required this.deletionFlagsBox,
    required this.logger,
  });

  @override
  Future<List<MeasurementModel>> getLastMeasurements({int limit = 100}) async {
    try {
      final List<MeasurementModel> result = [];

      // Converter valores do Hive para MeasurementModel
      final measurements = measurementsBox.values.toList();

      // Ordenar por data de medição (decrescente)
      measurements.sort((a, b) {
        final dateA = DateTime.parse(a['measuredAt'] as String);
        final dateB = DateTime.parse(b['measuredAt'] as String);
        return dateB.compareTo(dateA);
      });

      // Limitar resultados
      final limitedMeasurements = measurements.take(limit).toList();

      for (final measurement in limitedMeasurements) {
        final String id = measurement['id'] as String;
        result.add(
          MeasurementModel(
            id: id,
            systolic: measurement['systolic'] as int,
            diastolic: measurement['diastolic'] as int,
            heartRate: measurement['heartRate'] as int,
            measuredAt: DateTime.parse(measurement['measuredAt'] as String),
            createdAt: DateTime.parse(measurement['createdAt'] as String),
            notes: measurement['notes'] as String?,
            userId: measurement['userId'] as String,
          ),
        );
      }

      return result;
    } catch (e) {
      logger.e('Erro ao obter medições locais', e);
      throw CacheException('Erro ao ler medições do cache local');
    }
  }

  @override
  Future<void> cacheMeasurement(MeasurementModel measurement) async {
    try {
      await measurementsBox.put(
        measurement.id,
        {
          'id': measurement.id,
          'systolic': measurement.systolic,
          'diastolic': measurement.diastolic,
          'heartRate': measurement.heartRate,
          'measuredAt': measurement.measuredAt.toIso8601String(),
          'createdAt': measurement.createdAt.toIso8601String(),
          'notes': measurement.notes,
          'userId': measurement.userId,
        },
      );
    } catch (e) {
      logger.e('Erro ao salvar medição no cache', e);
      throw CacheException('Erro ao salvar medição no cache local');
    }
  }

  @override
  Future<void> cacheMeasurements(List<MeasurementModel> measurements) async {
    try {
      final Map<String, Map<String, dynamic>> entries = {};

      for (final measurement in measurements) {
        entries[measurement.id] = {
          'id': measurement.id,
          'systolic': measurement.systolic,
          'diastolic': measurement.diastolic,
          'heartRate': measurement.heartRate,
          'measuredAt': measurement.measuredAt.toIso8601String(),
          'createdAt': measurement.createdAt.toIso8601String(),
          'notes': measurement.notes,
          'userId': measurement.userId,
        };
      }

      await measurementsBox.putAll(entries);
    } catch (e) {
      logger.e('Erro ao salvar múltiplas medições no cache', e);
      throw CacheException('Erro ao salvar medições no cache local');
    }
  }

  @override
  Future<void> updateMeasurement(MeasurementModel measurement) async {
    try {
      await measurementsBox.put(
        measurement.id,
        {
          'id': measurement.id,
          'systolic': measurement.systolic,
          'diastolic': measurement.diastolic,
          'heartRate': measurement.heartRate,
          'measuredAt': measurement.measuredAt.toIso8601String(),
          'createdAt': measurement.createdAt.toIso8601String(),
          'notes': measurement.notes,
          'userId': measurement.userId,
        },
      );
    } catch (e) {
      logger.e('Erro ao atualizar medição no cache', e);
      throw CacheException('Erro ao atualizar medição no cache local');
    }
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    try {
      await measurementsBox.delete(id);
      // Remover quaisquer flags associadas
      await syncFlagsBox.delete(id);
      await deletionFlagsBox.delete(id);
    } catch (e) {
      logger.e('Erro ao excluir medição do cache', e);
      throw CacheException('Erro ao excluir medição do cache local');
    }
  }

  @override
  Future<void> markForSync(String id) async {
    try {
      await syncFlagsBox.put(id, true);
    } catch (e) {
      logger.e('Erro ao marcar medição para sincronização', e);
      throw CacheException('Erro ao marcar medição para sincronização');
    }
  }

  @override
  Future<void> markForDeletion(String id) async {
    try {
      await deletionFlagsBox.put(id, true);
    } catch (e) {
      logger.e('Erro ao marcar medição para exclusão', e);
      throw CacheException('Erro ao marcar medição para exclusão');
    }
  }

  @override
  Future<List<MeasurementModel>> getPendingSyncMeasurements() async {
    try {
      final List<MeasurementModel> result = [];

      for (final id in syncFlagsBox.keys) {
        final Map? measurementData = measurementsBox.get(id);
        if (measurementData != null) {
          result.add(
            MeasurementModel(
              id: measurementData['id'] as String,
              systolic: measurementData['systolic'] as int,
              diastolic: measurementData['diastolic'] as int,
              heartRate: measurementData['heartRate'] as int,
              measuredAt: DateTime.parse(measurementData['measuredAt'] as String),
              createdAt: DateTime.parse(measurementData['createdAt'] as String),
              notes: measurementData['notes'] as String?,
              userId: measurementData['userId'] as String,
            ),
          );
        }
      }

      return result;
    } catch (e) {
      logger.e('Erro ao obter medições pendentes de sincronização', e);
      throw CacheException('Erro ao obter medições pendentes de sincronização');
    }
  }

  @override
  Future<List<String>> getPendingDeletionIds() async {
    try {
      return deletionFlagsBox.keys.cast<String>().toList();
    } catch (e) {
      logger.e('Erro ao obter IDs pendentes de exclusão', e);
      throw CacheException('Erro ao obter IDs pendentes de exclusão');
    }
  }

  @override
  Future<void> clearSyncFlag(String id) async {
    try {
      await syncFlagsBox.delete(id);
    } catch (e) {
      logger.e('Erro ao limpar flag de sincronização', e);
      throw CacheException('Erro ao limpar flag de sincronização');
    }
  }

  @override
  Future<void> clearDeletionFlag(String id) async {
    try {
      await deletionFlagsBox.delete(id);
    } catch (e) {
      logger.e('Erro ao limpar flag de exclusão', e);
      throw CacheException('Erro ao limpar flag de exclusão');
    }
  }
}