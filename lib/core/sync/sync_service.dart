// core/sync/sync_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/data/datasources/local/measurement_local_datasource.dart';
import 'package:bp_monitor/core/network/network_info.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/core/remote_config/remote_config_service.dart';

class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MeasurementLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  final AppStrings _strings;
  final RemoteConfigService _remoteConfig;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required MeasurementLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required AppLogger logger,
    required AppStrings strings,
    required RemoteConfigService remoteConfig,
  }) : _firestore = firestore,
        _auth = auth,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _logger = logger,
        _strings = strings,
        _remoteConfig = remoteConfig;

  void startPeriodicSync() {
    _syncTimer?.cancel();
    final intervalMinutes = _remoteConfig.getInt('sync_interval_minutes');
    final interval = Duration(minutes: intervalMinutes);

    _syncTimer = Timer.periodic(interval, (_) => syncIfNeeded());
    _logger.i('Sincronização periódica iniciada: intervalo de $intervalMinutes minutos');
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _logger.i('Sincronização periódica interrompida');
  }

  Future<bool> syncIfNeeded() async {
    if (_isSyncing) {
      _logger.d('Sincronização já em andamento, ignorando');
      return false;
    }

    try {
      _isSyncing = true;

      // Verificar conectividade
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        _logger.d('Sem conexão, sincronização adiada');
        _isSyncing = false;
        return false;
      }

      // Verificar autenticação
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _logger.d('Usuário não autenticado, sincronização cancelada');
        _isSyncing = false;
        return false;
      }

      // 1. Sincronizar medições pendentes
      final pendingMeasurements = await _localDataSource.getPendingSyncMeasurements();
      if (pendingMeasurements.isNotEmpty) {
        _logger.i('Sincronizando ${pendingMeasurements.length} medições pendentes');

        for (final measurement in pendingMeasurements) {
          try {
            await _firestore
                .collection('measurements')
                .doc(measurement.id)
                .set(measurement.toJson());

            await _localDataSource.clearSyncFlag(measurement.id);
            _logger.d('Medição ${measurement.id} sincronizada com sucesso');
          } catch (e) {
            _logger.e('Erro ao sincronizar medição ${measurement.id}', e);
            // Continuar com a próxima medição
          }
        }
      }

      // 2. Processar exclusões pendentes
      final pendingDeletionIds = await _localDataSource.getPendingDeletionIds();
      if (pendingDeletionIds.isNotEmpty) {
        _logger.i('Processando ${pendingDeletionIds.length} exclusões pendentes');

        for (final id in pendingDeletionIds) {
          try {
            await _firestore.collection('measurements').doc(id).delete();
            await _localDataSource.clearDeletionFlag(id);
            _logger.d('Exclusão da medição $id sincronizada com sucesso');
          } catch (e) {
            _logger.e('Erro ao sincronizar exclusão da medição $id', e);
            // Continuar com a próxima exclusão
          }
        }
      }

      _logger.i(_strings.syncComplete);
      return true;
    } catch (e) {
      _logger.e(_strings.get('sync_error', defaultValue: 'Erro durante sincronização'), e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Força uma sincronização imediata
  Future<bool> forceSyncNow() {
    _logger.i('Sincronização forçada iniciada');
    return syncIfNeeded();
  }
}