import 'package:flutter/material.dart';

/// Constantes globais do aplicativo BP Monitor
class AppConstants {
  // Informações do App
  static const String appName = 'BP Monitor';
  static const String appDescription = 'Controle sua pressão arterial';
  static const String version = '1.0.0';

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
  static const int maxDiastolic = 150;
  static const int minHeartRate = 30;
  static const int maxHeartRate = 220;

  // Classificações de Pressão
  static const Map<String, Map<String, dynamic>> pressureCategories = {
    'otima': {
      'name': 'Ótima',
      'systolicMax': 120,
      'diastolicMax': 80,
      'color': Colors.green,
    },
    'normal': {
      'name': 'Normal',
      'systolicMax': 129,
      'diastolicMax': 84,
      'color': Colors.blue,
    },
    'elevated': {
      'name': 'Elevada',
      'systolicMax': 130,
      'diastolicMax': 89,
      'color': Colors.orange,
    },
    'high': {
      'name': 'Alta',
      'systolicMax': 140, // Sem limite superior
      'diastolicMax': 90,
      'color': Colors.red,
    },
  };

  // Cores do App
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFDC2626);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

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
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 1200);

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

  // Mensagens
  static const String dataSecurityMessage =
      'Seus dados sempre seguros no seu dispositivo';
  static const String noDataMessage = 'Nenhuma medição registrada';
  static const String validationNameError = 'Por favor, insira seu nome';
  static const String validationBirthDateError =
      'Por favor, insira sua data de nascimento';
  static const String validationAgeError =
      'Por favor, verifique sua data de nascimento';
  static const String measurementSavedSuccess = 'Medição salva com sucesso!';
  static const String fillAllFieldsError =
      'Por favor, preencha todos os campos obrigatórios';

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
}