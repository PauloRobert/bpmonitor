import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:bp_monitor/core/remote_config/remote_config_defaults.dart';
import 'package:bp_monitor/core/utils/logger.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  final AppLogger _logger;

  RemoteConfigService._({
    required FirebaseRemoteConfig remoteConfig,
    required AppLogger logger,
  }) : _remoteConfig = remoteConfig,
        _logger = logger;

  static Future<RemoteConfigService> getInstance(AppLogger logger) async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      await remoteConfig.setDefaults(RemoteConfigDefaults.defaults);
      await remoteConfig.fetchAndActivate();

      logger.i('Remote Config inicializado com sucesso');
      return RemoteConfigService._(remoteConfig: remoteConfig, logger: logger);
    } catch (e) {
      logger.e('Erro ao configurar Remote Config', e);
      return RemoteConfigService._(remoteConfig: remoteConfig, logger: logger);
    }
  }

  int getInt(String key) => _remoteConfig.getInt(key);
  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  Color getColor(String key) {
    try {
      final hexColor = getString(key);
      if (hexColor.isEmpty || !hexColor.startsWith('#')) {
        return Colors.blue; // Valor padrão em caso de erro
      }

      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      _logger.e('Erro ao converter cor do Remote Config: $key', e);
      return Colors.blue; // Valor padrão em caso de erro
    }
  }

  Future<bool> forceRefresh() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      _logger.i('Remote Config atualizado: $updated');
      return updated;
    } catch (e) {
      _logger.e('Erro ao atualizar Remote Config', e);
      return false;
    }
  }
}