class RemoteConfigDefaults {
  // Medição
  static const Map<String, dynamic> defaults = {
    // Limites de medição
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

    // Cores das categorias
    'optimal_color': '#10B981',
    'normal_color': '#3B82F6',
    'elevated_color': '#F59E0B',
    'high_stage1_color': '#EF4444',
    'high_stage2_color': '#DC2626',
    'crisis_color': '#7C3AED',

    // Configurações de sincronização
    'sync_interval_minutes': 15,
    'force_sync_on_login': true,
    'force_sync_on_measurement': true,

    // Funcionalidades habilitadas
    'enable_charts': true,
    'enable_reports': true,
    'enable_notifications': true,

    // Strings do aplicativo - Geral
    'str_app_name': 'BP Monitor',
    'str_app_description': 'Monitore sua pressão arterial de forma simples e eficiente',

    // Strings - Autenticação
    'str_login_with_google': 'Entrar com Google',
    'str_login_canceled': 'Login cancelado pelo usuário',
    'str_login_error': 'Falha ao obter dados do usuário',
    'str_unauthenticated': 'Usuário não autenticado',

    // Strings - Categorias de pressão
    'str_optimal_category': 'Ótima',
    'str_normal_category': 'Normal',
    'str_elevated_category': 'Elevada',
    'str_high_stage1_category': 'Alta Estágio 1',
    'str_high_stage2_category': 'Alta Estágio 2',
    'str_crisis_category': 'Crise Hipertensiva',

    // Strings - Mensagens de feedback
    'str_measurement_saved': 'Medição salva com sucesso!',
    'str_measurement_updated': 'Medição atualizada com sucesso!',
    'str_measurement_deleted': 'Medição removida com sucesso!',
    'str_sync_complete': 'Sincronização concluída',
    'str_sync_error': 'Erro na sincronização',
    'str_offline_mode': 'Modo offline ativado',

    // Strings - Erros
    'str_server_error': 'Erro ao carregar dados do servidor',
    'str_cache_error': 'Erro ao carregar dados locais',
    'str_measurement_error': 'Erro ao processar medição',
  };
}