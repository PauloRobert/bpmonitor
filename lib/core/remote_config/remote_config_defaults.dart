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

    // Mensagens personalizáveis
    'optimal_message': 'Sua pressão está ótima!',
    'normal_message': 'Sua pressão está normal',
    'elevated_message': 'Sua pressão está um pouco elevada',
    'high_stage1_message': 'Sua pressão está alta, consulte seu médico',
    'high_stage2_message': 'Sua pressão está muito alta, consulte seu médico',
    'crisis_message': 'EMERGÊNCIA: Procure atendimento médico imediatamente',
  };
}