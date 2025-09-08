// data/repositories/measurement_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bp_monitor/core/error/exceptions.dart';
import 'package:bp_monitor/core/error/failures.dart';
import 'package:bp_monitor/core/network/network_info.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/data/datasources/local/measurement_local_datasource.dart';
import 'package:bp_monitor/data/models/measurement_model.dart';
import 'package:bp_monitor/domain/entities/measurement_entity.dart';
import 'package:bp_monitor/domain/repositories/measurement_repository.dart';
import 'package:uuid/uuid.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  final FirebaseFirestore firestore;
  final MeasurementLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AppLogger logger;
  final FirebaseAuth _auth;
  final AppStrings _strings;

  MeasurementRepositoryImpl({
    required this.firestore,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
    required FirebaseAuth auth,
    required AppStrings strings,
  }) : _auth = auth,
        _strings = strings;

  @override
  Future<Either<Failure, List<MeasurementEntity>>> getMeasurements() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(_strings.get('unauthenticated')));
      }

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final snapshot = await firestore
              .collection('measurements')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('measuredAt', descending: true)
              .get();

          final measurements = snapshot.docs
              .map((doc) => MeasurementModel.fromFirestore(
            doc.data(),
            doc.id,
          ).toEntity())
              .toList();

          // Atualizar cache local
          await localDataSource.cacheMeasurements(
            snapshot.docs
                .map((doc) => MeasurementModel.fromFirestore(
              doc.data(),
              doc.id,
            ))
                .toList(),
          );

          return Right(measurements);
        } catch (e) {
          logger.e('Erro ao buscar medições do Firestore', e);
          // Fallback para dados locais em caso de erro
          final localMeasurements = await localDataSource.getLastMeasurements();
          return Right(localMeasurements.map((model) => model.toEntity()).toList());
        }
      } else {
        // Offline: buscar do cache
        final localMeasurements = await localDataSource.getLastMeasurements();
        return Right(localMeasurements.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      logger.e('Erro de cache ao buscar medições', e);
      return Left(CacheFailure(_strings.get('cache_error')));
    } catch (e) {
      logger.e('Erro desconhecido ao buscar medições', e);
      return Left(ServerFailure(_strings.get('server_error')));
    }
  }

  @override
  Future<Either<Failure, List<MeasurementEntity>>> getRecentMeasurements({
    int limit = 10,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(_strings.get('unauthenticated')));
      }

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final snapshot = await firestore
              .collection('measurements')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('measuredAt', descending: true)
              .limit(limit)
              .get();

          final measurements = snapshot.docs
              .map((doc) => MeasurementModel.fromFirestore(
            doc.data(),
            doc.id,
          ).toEntity())
              .toList();

          return Right(measurements);
        } catch (e) {
          logger.e('Erro ao buscar medições recentes do Firestore', e);
          // Fallback para dados locais
          final localMeasurements = await localDataSource.getLastMeasurements(limit: limit);
          return Right(localMeasurements.map((model) => model.toEntity()).toList());
        }
      } else {
        // Offline: buscar do cache
        final localMeasurements = await localDataSource.getLastMeasurements(limit: limit);
        return Right(localMeasurements.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      logger.e('Erro de cache ao buscar medições recentes', e);
      return Left(CacheFailure(_strings.get('cache_error')));
    } catch (e) {
      logger.e('Erro desconhecido ao buscar medições recentes', e);
      return Left(ServerFailure(_strings.get('server_error')));
    }
  }

  @override
  Future<Either<Failure, MeasurementEntity>> saveMeasurement(
      MeasurementEntity measurement,
      ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(_strings.get('unauthenticated')));
      }

      // Criar ID se necessário
      final String id = measurement.id.isEmpty ? const Uuid().v4() : measurement.id;

      // Converter para model
      final measurementModel = MeasurementModel.fromEntity(
        measurement.id.isEmpty
            ? measurement.copyWith(id: id)
            : measurement,
        currentUser.uid,
      );

      // Salvar localmente primeiro
      await localDataSource.cacheMeasurement(measurementModel);

      // Tentar salvar remotamente se conectado
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await firestore
              .collection('measurements')
              .doc(id)
              .set(measurementModel.toJson());
        } catch (e) {
          logger.w('Erro ao salvar medição no Firestore, apenas cache local foi atualizado', e);
          // Não falhar completamente se o Firestore falhar, já salvamos localmente
        }
      } else {
        // Marcar para sincronização futura
        await localDataSource.markForSync(id);
        logger.i(_strings.get('offline_mode'));
      }

      return Right(measurementModel.toEntity());
    } on CacheException catch (e) {
      logger.e('Erro de cache ao salvar medição', e);
      return Left(CacheFailure(_strings.get('cache_error')));
    } catch (e) {
      logger.e('Erro desconhecido ao salvar medição', e);
      return Left(ServerFailure(_strings.get('measurement_error')));
    }
  }

  @override
  Future<Either<Failure, MeasurementEntity>> updateMeasurement(
      MeasurementEntity measurement,
      ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(_strings.get('unauthenticated')));
      }

      if (measurement.id.isEmpty) {
        return Left(ServerFailure(_strings.get('measurement_error', defaultValue: 'ID da medição não fornecido')));
      }

      // Converter para model
      final measurementModel = MeasurementModel.fromEntity(
        measurement,
        currentUser.uid,
      );

      // Atualizar localmente primeiro
      await localDataSource.updateMeasurement(measurementModel);

      // Tentar atualizar remotamente se conectado
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await firestore
              .collection('measurements')
              .doc(measurement.id)
              .update(measurementModel.toJson());
        } catch (e) {
          logger.w('Erro ao atualizar medição no Firestore, apenas cache local foi atualizado', e);
          // Não falhar completamente se o Firestore falhar
        }
      } else {
        // Marcar para sincronização futura
        await localDataSource.markForSync(measurement.id);
        logger.i(_strings.get('offline_mode'));
      }

      return Right(measurementModel.toEntity());
    } on CacheException catch (e) {
      logger.e('Erro de cache ao atualizar medição', e);
      return Left(CacheFailure(_strings.get('cache_error')));
    } catch (e) {
      logger.e('Erro desconhecido ao atualizar medição', e);
      return Left(ServerFailure(_strings.get('measurement_error')));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMeasurement(String id) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(_strings.get('unauthenticated')));
      }

      if (id.isEmpty) {
        return Left(ServerFailure(_strings.get('measurement_error', defaultValue: 'ID da medição não fornecido')));
      }

      // Excluir localmente primeiro
      await localDataSource.deleteMeasurement(id);

      // Tentar excluir remotamente se conectado
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await firestore
              .collection('measurements')
              .doc(id)
              .delete();
        } catch (e) {
          logger.w('Erro ao excluir medição no Firestore, apenas cache local foi atualizado', e);
          // Não falhar completamente se o Firestore falhar
        }
      } else {
        // Marcar para exclusão na próxima sincronização
        await localDataSource.markForDeletion(id);
        logger.i(_strings.get('offline_mode'));
      }

      return const Right(true);
    } on CacheException catch (e) {
      logger.e('Erro de cache ao excluir medição', e);
      return Left(CacheFailure(_strings.get('cache_error')));
    } catch (e) {
      logger.e('Erro desconhecido ao excluir medição', e);
      return Left(ServerFailure(_strings.get('measurement_error')));
    }
  }
}