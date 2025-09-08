import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService._({required FirebaseRemoteConfig remoteConfig})
      : _remoteConfig = remoteConfig;

  static Future<RemoteConfigService> getInstance() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ));

    await remoteConfig.setDefaults({
      // Valores padrão de pressão
      'min_systolic': 70,
      'max_systolic': 250,
      'min_diastolic': 40,
      'max_diastolic': 150,
      'min_heart_rate': 30,
      'max_heart_rate': 220,
      // Categorias de pressão
      'optimal_systolic_max': 120,
      'optimal_diastolic_max': 80,
      'normal_systolic_max': 129,
      'normal_diastolic_max': 84,
      'elevated_systolic_max': 130,
      'elevated_diastolic_max': 89,
      'high_stage1_systolic_max': 139,
      'high_stage1_diastolic_max': 89,
      'high_stage2_systolic_max': 179,
      'high_stage2_diastolic_max': 119,
    });

    await remoteConfig.fetchAndActivate();

    return RemoteConfigService._(remoteConfig: remoteConfig);
  }

  int getInt(String key) => _remoteConfig.getInt(key);
  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);
}