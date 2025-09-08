import 'package:bp_monitor/core/remote_config/remote_config_service.dart';

class AppStrings {
  final RemoteConfigService _remoteConfig;

  AppStrings(this._remoteConfig);

  // Prefixo para identificar strings no Remote Config
  static const _prefix = 'str_';

  // Método para obter textos do Remote Config
  String get(String key, {String defaultValue = ''}) {
    final remoteKey = '$_prefix$key';
    final value = _remoteConfig.getString(remoteKey);

    // Se o valor do Remote Config estiver vazio, usar o valor padrão
    return value.isEmpty ? defaultValue : value;
  }

  // SEÇÕES DE STRINGS ORGANIZADAS POR CATEGORIA

  // Geral
  String get appName => get('app_name', defaultValue: 'BP Monitor');
  String get appDescription => get('app_description', defaultValue: 'Controle sua pressão arterial');

  // Autenticação
  String get loginWithGoogle => get('login_with_google', defaultValue: 'Entrar com Google');
  String get loginError => get('login_error', defaultValue: 'Erro ao fazer login');

  // Categorias de pressão
  String get optimalPressure => get('optimal_pressure', defaultValue: 'Ótima');
  String get normalPressure => get('normal_pressure', defaultValue: 'Normal');
  String get elevatedPressure => get('elevated_pressure', defaultValue: 'Elevada');
  String get highStage1Pressure => get('high_stage1_pressure', defaultValue: 'Alta Estágio 1');
  String get highStage2Pressure => get('high_stage2_pressure', defaultValue: 'Alta Estágio 2');
  String get crisisPressure => get('crisis_pressure', defaultValue: 'Crise Hipertensiva');

  // Mensagens de feedback
  String get measurementSaved => get('measurement_saved', defaultValue: 'Medição salva com sucesso!');
  String get syncComplete => get('sync_complete', defaultValue: 'Sincronização concluída');
  String get offlineMode => get('offline_mode', defaultValue: 'Modo offline ativado');

// ... Mais categorias de strings
}