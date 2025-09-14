import 'package:flutter/material.dart';

/// Constantes globais do aplicativo BP Monitor
class AppConstants {
  // Informações do App
  static const String appName = 'BP Monitor';
  static const String appDescription = 'Controle sua pressão arterial';
  static const String version = '1.1.1';

  // Logs Tags
  static const String logTag = '[BP_MONITOR]';

  // Database
  static const String databaseName = 'bp_monitor.db';
  static const int databaseVersion = 1;

  // Tabelas
  static const String measurementsTable = 'measurements';
  static const String usersTable = 'users';

  // SharedPreferences Keys
  static const String onboardingCompleteKey = 'onboardingComplete';

  // Rotas (Routes)
  static const String mainRoute = '/main';
  static const String onboardingRoute = '/onboarding';

  // Validações de Medição
  static const int minSystolic = 70;
  static const int maxSystolic = 250;
  static const int minDiastolic = 40;
  static const int maxDiastolic = 130;
  static const int minHeartRate = 50;
  static const int maxHeartRate = 220;

  // ✅ COMPLETO: Classificações de Pressão baseadas no Ministério da Saúde
  // Incluindo hipotensão (pressão baixa) conforme referência oficial
  // Fonte: https://www.gov.br/conitec/pt-br/midias/protocolos/pcdt-hipertensao-arterial-sistemica.pdf
  static const Map<String, Map<String, dynamic>> pressureCategories = {
    'hypotension': {
      'name': 'Hipotensão',
      'description': 'Pressão arterial baixa - pode causar sintomas',
      'systolicMax': 90,      // PAS < 90
      'diastolicMax': 60,     // PAD < 60
      'color': Color(0xFF6366F1), // Índigo/Roxo claro
      'priority': 0,
    },
    'optimal': {
      'name': 'Ótima',
      'description': 'Pressão arterial ótima',
      'systolicMax': 120,     // PAS < 120
      'diastolicMax': 80,     // PAD < 80
      'color': Color(0xFF10B981), // Verde
      'priority': 1,
    },
    'normal': {
      'name': 'Normal',
      'description': 'Pressão arterial normal',
      'systolicMax': 129,     // PAS 120-129
      'diastolicMax': 84,     // PAD 80-84
      'color': Color(0xFF3B82F6), // Azul
      'priority': 2,
    },
    'elevated': {
      'name': 'Normal Alta',
      'description': 'Pressão arterial normal alta',
      'systolicMax': 139,     // PAS 130-139
      'diastolicMax': 89,     // PAD 85-89
      'color': Color(0xFFF59E0B), // Amarelo/Laranja
      'priority': 3,
    },
    'high_stage1': {
      'name': 'Hipertensão Grau 1',
      'description': 'Hipertensão arterial grau 1',
      'systolicMax': 159,     // PAS 140-159
      'diastolicMax': 99,     // PAD 90-99
      'color': Color(0xFFEF4444), // Vermelho claro
      'priority': 4,
    },
    'high_stage2': {
      'name': 'Hipertensão Grau 2',
      'description': 'Hipertensão arterial grau 2',
      'systolicMax': 179,     // PAS 160-179
      'diastolicMax': 109,    // PAD 100-109
      'color': Color(0xFFDC2626), // Vermelho escuro
      'priority': 5,
    },
    'crisis': {
      'name': 'Hipertensão Grau 3',
      'description': 'Emergência hipertensiva - procure atendimento médico imediato',
      'systolicMax': 999,     // PAS ≥ 180 (sem limite superior)
      'diastolicMax': 999,    // PAD ≥ 110 (sem limite superior)
      'color': Color(0xFF7C3AED), // Roxo
      'priority': 6,
    },
  };

  // Cores do App
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFDC2626);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // ✅ FIX: Cores de alerta médico
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color criticalColor = Color(0xFF7C3AED);

  // Gradientes
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFFDC2626),
    ],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),
      Color(0xFF2563EB),
    ],
  );

  // Duração de animações
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 400);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 600);

  // Onboarding
  static const List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Bem-vindo ao BP Monitor',
      'content': 'Registre suas medições de pressão arterial de forma simples e organize seus dados para compartilhar com seu médico.',
      'icon': Icons.favorite,
    },
    {
      'title': 'Visualize sua Evolução',
      'content': 'Acompanhe seus dados através de gráficos e listas organizadas, com insights sobre sua pressão ao longo do tempo.',
      'icon': Icons.trending_up,
    },
    {
      'title': 'Compartilhe com seu Médico',
      'content': 'Gere relatórios em PDF com seus dados organizados para levar às consultas médicas.',
      'icon': Icons.description,
    },
  ];

  // Tamanhos
  static const double logoSizeLarge = 96.0;
  static const double logoSizeSmall = 64.0;
  static const double borderRadius = 12.0;
  static const double cardPadding = 16.0;

  // ✅ FIX: Mensagens de feedback melhoradas
  static const String dataSecurityMessage =
      'Seus dados sempre seguros no seu dispositivo';
  static const String noDataMessage = 'Nenhuma medição registrada';
  static const String validationNameError = 'Por favor, insira seu nome';
  static const String validationBirthDateError =
      'Por favor, insira sua data de nascimento';
  static const String validationAgeError =
      'Por favor, verifique sua data de nascimento';
  static const String measurementSavedSuccess = 'Medição salva com sucesso!';
  static const String measurementUpdatedSuccess = 'Medição atualizada com sucesso!';
  static const String measurementDeletedSuccess = 'Medição removida com sucesso!';
  static const String fillAllFieldsError =
      'Por favor, preencha todos os campos obrigatórios';

  // ✅ FIX: Mensagens de alerta médico
  static const String urgentAttentionMessage =
      'ATENÇÃO: Valores indicam necessidade de avaliação médica urgente';
  static const String highPressureMessage =
      'Pressão alta detectada. Considere consultar seu médico';
  static const String lowPressureMessage =
      'Pressão baixa detectada. Considere consultar seu médico';
  static const String measurementTipsMessage =
      'Dica: Descanse 5 minutos antes de medir e mantenha os pés no chão';

  // ✅ FIX: Configurações de paginação
  static const int defaultPageSize = 20;
  static const int maxItemsInMemory = 100;

  // Logs personalizados com níveis
  static void logInfo(String message) {
    debugPrint('$logTag [INFO] $message');
  }

  static void logWarning(String message) {
    debugPrint('$logTag [WARNING] $message');
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$logTag [ERROR] $message');
    if (error != null) {
      debugPrint('$logTag [ERROR] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('$logTag [ERROR] StackTrace: $stackTrace');
    }
  }

  static void logDatabase(String operation, String table, [String? details]) {
    debugPrint('$logTag [DATABASE] $operation on $table ${details ?? ''}');
  }

  static void logNavigation(String from, String to) {
    debugPrint('$logTag [NAVIGATION] From $from to $to');
  }

  // ✅ FIX: Novos métodos de log para diferentes contextos
  static void logMedical(String message) {
    debugPrint('$logTag [MEDICAL] $message');
  }

  static void logPerformance(String operation, int duration) {
    debugPrint('$logTag [PERFORMANCE] $operation took ${duration}ms');
  }

  static void logUserAction(String action, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' - Data: $data' : '';
    debugPrint('$logTag [USER_ACTION] $action$dataStr');
  }
}

/// ============================================================================
/// PressureClassifier - Fonte única de verdade para classificação de pressão
/// Baseado nas diretrizes do Ministério da Saúde + Hipotensão
/// ============================================================================
class PressureClassifier {
  /// Classifica uma medição de pressão arterial incluindo hipotensão
  static String classifyPressure(int systolic, int diastolic) {
    try {
      // ✅ NOVO: Hipotensão - PAS < 90 OU PAD < 60
      if (systolic < 90 || diastolic < 60) {
        AppConstants.logMedical('Pressão $systolic/$diastolic - HIPOTENSÃO detectada');
        return 'hypotension';
      }

      // Hipertensão Grau 3 (Crise Hipertensiva) - PAS ≥ 180 OU PAD ≥ 110
      if (systolic >= 180 || diastolic >= 110) {
        AppConstants.logMedical('Pressão $systolic/$diastolic - HIPERTENSÃO GRAU 3 (CRISE) detectada');
        return 'crisis';
      }

      // Hipertensão Grau 2 - PAS 160-179 OU PAD 100-109
      if (systolic >= 160 || diastolic >= 100) {
        AppConstants.logMedical('Pressão $systolic/$diastolic classificada como: Hipertensão Grau 2');
        return 'high_stage2';
      }

      // Hipertensão Grau 1 - PAS 140-159 OU PAD 90-99
      if (systolic >= 140 || diastolic >= 90) {
        AppConstants.logMedical('Pressão $systolic/$diastolic classificada como: Hipertensão Grau 1');
        return 'high_stage1';
      }

      // Normal Alta - PAS 130-139 E PAD 85-89
      if (systolic >= 130 && systolic <= 139 && diastolic >= 85 && diastolic <= 89) {
        AppConstants.logMedical('Pressão $systolic/$diastolic classificada como: Normal Alta');
        return 'elevated';
      }

      // Normal - PAS 120-129 E PAD 80-84
      if (systolic >= 120 && systolic <= 129 && diastolic >= 80 && diastolic <= 84) {
        AppConstants.logMedical('Pressão $systolic/$diastolic classificada como: Normal');
        return 'normal';
      }

      // Ótima - PAS 90-119 E PAD 60-79 (ajustado para não conflitar com hipotensão)
      if (systolic >= 90 && systolic < 120 && diastolic >= 60 && diastolic < 80) {
        AppConstants.logMedical('Pressão $systolic/$diastolic classificada como: Ótima');
        return 'optimal';
      }

      // Casos especiais que não se encaixam perfeitamente
      if (systolic >= 130) {
        AppConstants.logMedical('Pressão $systolic/$diastolic - Sistólica elevada, classificada como Normal Alta');
        return 'elevated';
      }

      // Fallback para ótima se valores estão na faixa normal mas não se encaixam perfeitamente
      AppConstants.logMedical('Pressão $systolic/$diastolic não se encaixou perfeitamente - usando Ótima');
      return 'optimal';

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao determinar categoria da pressão', e, stackTrace);
      return 'high_stage2'; // Default para alta em caso de erro
    }
  }

  /// Obtém os dados completos de uma categoria de pressão
  static Map<String, dynamic> getCategoryData(String category) {
    return AppConstants.pressureCategories[category] ??
        AppConstants.pressureCategories['high_stage2']!;
  }

  /// Obtém o nome de uma categoria
  static String getCategoryName(String category) {
    return getCategoryData(category)['name'] as String;
  }

  /// Obtém a cor de uma categoria
  static Color getCategoryColor(String category) {
    return getCategoryData(category)['color'] as Color;
  }

  /// Obtém a descrição de uma categoria
  static String getCategoryDescription(String category) {
    return getCategoryData(category)['description'] as String;
  }

  /// Obtém a prioridade de uma categoria (para ordenação)
  static int getCategoryPriority(String category) {
    return getCategoryData(category)['priority'] as int;
  }

  /// Verifica se uma categoria indica necessidade de atenção médica urgente
  static bool needsUrgentAttention(String category) {
    return ['hypotension', 'crisis'].contains(category);
  }

  /// Verifica se uma categoria indica pressão alta (hipertensão)
  static bool isHighPressure(String category) {
    return ['high_stage1', 'high_stage2', 'crisis'].contains(category);
  }

  /// ✅ NOVO: Verifica se uma categoria indica pressão baixa (hipotensão)
  static bool isLowPressure(String category) {
    return category == 'hypotension';
  }

  /// Verifica se uma categoria indica pressão dentro da normalidade
  static bool isNormalPressure(String category) {
    return ['optimal', 'normal'].contains(category);
  }

  /// Obtém todas as categorias ordenadas por prioridade
  static List<String> getAllCategoriesOrdered() {
    final categories = AppConstants.pressureCategories.keys.toList();
    categories.sort((a, b) => getCategoryPriority(a).compareTo(getCategoryPriority(b)));
    return categories;
  }

  /// Obtém recomendação médica baseada na categoria
  static String getMedicalRecommendation(String category) {
    switch (category) {
      case 'hypotension':
        return 'Pressão baixa detectada. Considere aumentar a ingestão de líquidos e consulte seu médico se houver sintomas como tontura ou fraqueza.';
      case 'optimal':
        return 'Mantenha hábitos saudáveis e continue monitorando.';
      case 'normal':
        return 'Pressão normal. Continue com acompanhamento regular.';
      case 'elevated':
        return 'Pressão normal alta. Considere mudanças no estilo de vida e acompanhamento médico.';
      case 'high_stage1':
        return 'Hipertensão Grau 1. Procure orientação médica para avaliação e possível tratamento.';
      case 'high_stage2':
        return 'Hipertensão Grau 2. Consulte seu médico para avaliação e tratamento adequado.';
      case 'crisis':
        return 'EMERGÊNCIA HIPERTENSIVA. Procure atendimento médico IMEDIATAMENTE.';
      default:
        return 'Consulte seu médico para avaliação adequada.';
    }
  }
}