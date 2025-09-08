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
  String get appDescription => get('app_description', defaultValue: 'Monitore sua pressão arterial de forma simples e eficiente');
  String get version => get('version', defaultValue: 'Versão 1.0.0');

  // Autenticação
  String get loginWithGoogle => get('login_with_google', defaultValue: 'Entrar com Google');
  String get loginCanceled => get('login_canceled', defaultValue: 'Login cancelado pelo usuário');
  String get loginError => get('login_error', defaultValue: 'Falha ao obter dados do usuário');
  String get unauthenticated => get('unauthenticated', defaultValue: 'Usuário não autenticado');

  // Categorias de pressão
  String get optimalCategory => get('optimal_category', defaultValue: 'Ótima');
  String get normalCategory => get('normal_category', defaultValue: 'Normal');
  String get elevatedCategory => get('elevated_category', defaultValue: 'Elevada');
  String get highStage1Category => get('high_stage1_category', defaultValue: 'Alta Estágio 1');
  String get highStage2Category => get('high_stage2_category', defaultValue: 'Alta Estágio 2');
  String get crisisCategory => get('crisis_category', defaultValue: 'Crise Hipertensiva');

  // Mensagens de feedback
  String get measurementSaved => get('measurement_saved', defaultValue: 'Medição salva com sucesso!');
  String get measurementUpdated => get('measurement_updated', defaultValue: 'Medição atualizada com sucesso!');
  String get measurementDeleted => get('measurement_deleted', defaultValue: 'Medição removida com sucesso!');
  String get syncComplete => get('sync_complete', defaultValue: 'Sincronização concluída');
  String get syncError => get('sync_error', defaultValue: 'Erro na sincronização');
  String get offlineMode => get('offline_mode', defaultValue: 'Modo offline ativado');

  // Erros
  String get serverError => get('server_error', defaultValue: 'Erro ao carregar dados do servidor');
  String get cacheError => get('cache_error', defaultValue: 'Erro ao carregar dados locais');
  String get measurementError => get('measurement_error', defaultValue: 'Erro ao processar medição');

  // Navegação
  String get home => get('nav_home', defaultValue: 'Início');
  String get history => get('nav_history', defaultValue: 'Histórico');
  String get statistics => get('nav_statistics', defaultValue: 'Estatísticas');
  String get profile => get('nav_profile', defaultValue: 'Perfil');
  String get addMeasurement => get('nav_add_measurement', defaultValue: 'Nova Medição');
  String get editMeasurement => get('nav_edit_measurement', defaultValue: 'Editar Medição');

  // Formulário de Medição
  String get systolic => get('form_systolic', defaultValue: 'Sistólica (mmHg)');
  String get diastolic => get('form_diastolic', defaultValue: 'Diastólica (mmHg)');
  String get heartRate => get('form_heart_rate', defaultValue: 'Batimentos (bpm)');
  String get date => get('form_date', defaultValue: 'Data');
  String get time => get('form_time', defaultValue: 'Hora');
  String get notes => get('form_notes', defaultValue: 'Observações (opcional)');
  String get save => get('form_save', defaultValue: 'Salvar');
  String get cancel => get('form_cancel', defaultValue: 'Cancelar');
  String get delete => get('form_delete', defaultValue: 'Excluir');

  // Textos de UI
  String get loading => get('ui_loading', defaultValue: 'Carregando...');
  String get noMeasurements => get('ui_no_measurements', defaultValue: 'Nenhuma medição registrada');
  String get tryAgain => get('ui_try_again', defaultValue: 'Tentar novamente');
  String get lastMeasurements => get('ui_last_measurements', defaultValue: 'Últimas Medições');
  String get viewAll => get('ui_view_all', defaultValue: 'Ver todas');
  String get weeklyAverage => get('ui_weekly_average', defaultValue: 'Média Semanal');
}