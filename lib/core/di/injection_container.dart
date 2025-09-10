// core/di/injection_container.dart (INICIALIZAÇÃO CORRETA PARA v7)
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';

import 'package:bp_monitor/core/analytics/analytics_service.dart';
import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/core/network/network_info.dart';
import 'package:bp_monitor/core/local/hive_setup.dart';
import 'package:bp_monitor/core/local/migration_service.dart';
import 'package:bp_monitor/core/sync/sync_service.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/core/theme/app_theme.dart';
import 'package:bp_monitor/data/datasources/local/measurement_local_datasource.dart';
import 'package:bp_monitor/data/repositories/auth_repository_impl.dart';
import 'package:bp_monitor/data/repositories/measurement_repository_impl.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';
import 'package:bp_monitor/domain/repositories/measurement_repository.dart';
import 'package:bp_monitor/domain/usecases/get_pressure_category.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Componentes externos
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics.instance);
  sl.registerSingleton<FirebaseCrashlytics>(FirebaseCrashlytics.instance);

  // CORREÇÃO: Google Sign-In v7 - Inicialização assíncrona obrigatória
  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize();
  sl.registerSingleton<GoogleSignIn>(googleSignIn);

  sl.registerSingleton<InternetConnectionChecker>(InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(seconds: 5),
    checkInterval: const Duration(seconds: 60),
  ));

  // Core - Utils & Network
  final logger = AppLoggerImpl();
  sl.registerSingleton<AppLogger>(logger);
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  // Core - Inicialização e Migração
  await HiveSetup.initialize(logger);

  final migrationService = MigrationService(
    prefs: sharedPreferences,
    logger: logger,
  );
  sl.registerSingleton<MigrationService>(migrationService);
  await migrationService.checkAndRunMigrations();

  // Core - Remote Config
  final remoteConfig = await RemoteConfigService.getInstance(logger);
  sl.registerSingleton<RemoteConfigService>(remoteConfig);

  // Core - Strings e Tema
  sl.registerLazySingleton(() => AppStrings(sl()));
  sl.registerLazySingleton(() => AppTheme(remoteConfig: sl()));

  // Core - Analytics
  final analyticsService = AnalyticsService(
    analytics: sl(),
    crashlytics: sl(),
    logger: sl(),
  );
  sl.registerSingleton<AnalyticsService>(analyticsService);
  await analyticsService.init();

  // Local Data Sources
  sl.registerLazySingleton<MeasurementLocalDataSource>(
        () => MeasurementLocalDataSourceImpl(
      measurementsBox: HiveSetup.getMeasurementsBox(),
      syncFlagsBox: HiveSetup.getSyncFlagsBox(),
      deletionFlagsBox: HiveSetup.getDeletionFlagsBox(),
      logger: sl(),
    ),
  );

  // Repositories
  _registerRepositories();

  // Use cases
  _registerUseCases();

  // Sync Service (depende dos repositórios)
  sl.registerSingleton<SyncService>(
    SyncService(
      firestore: sl(),
      auth: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
      strings: sl(),
      remoteConfig: sl(),
    ),
  );

  // BLoCs
  _registerBlocs();

  logger.i('Injeção de dependências concluída');
}

// Versão simplificada para teste inicial (sem Firebase)
Future<void> initWithoutFirebase() async {
  // Core - Utils
  final logger = AppLoggerImpl();
  sl.registerSingleton<AppLogger>(logger);

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Hive Setup básico
  await HiveSetup.initialize(logger);

  // Remote Config Mock
  sl.registerSingleton<RemoteConfigService>(MockRemoteConfigService(logger));

  // Strings e Tema
  sl.registerLazySingleton(() => AppStrings(sl()));
  sl.registerLazySingleton(() => AppTheme(remoteConfig: sl()));

  logger.i('Inicialização básica concluída (sem Firebase)');
}

void _registerRepositories() {
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
      logger: sl(),
      strings: sl(),
    ),
  );

  sl.registerLazySingleton<MeasurementRepository>(
        () => MeasurementRepositoryImpl(
      firestore: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
      auth: sl(),
      strings: sl(),
    ),
  );
}

void _registerUseCases() {
  sl.registerLazySingleton(() => GetPressureCategory(
    remoteConfig: sl(),
    strings: sl(),
  ));
}

void _registerBlocs() {
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  // Outros blocs serão adicionados aqui
}

// Mock do RemoteConfig para teste
class MockRemoteConfigService implements RemoteConfigService {
  final AppLogger _logger;

  MockRemoteConfigService(this._logger);

  @override
  int getInt(String key) {
    switch (key) {
      case 'sync_interval_minutes': return 15;
      case 'optimal_systolic_max': return 120;
      case 'optimal_diastolic_max': return 80;
      case 'normal_systolic_max': return 129;
      case 'normal_diastolic_max': return 84;
      case 'elevated_systolic_max': return 130;
      case 'elevated_diastolic_max': return 89;
      case 'high_stage1_systolic_max': return 139;
      case 'high_stage1_diastolic_max': return 89;
      case 'high_stage2_systolic_max': return 179;
      case 'high_stage2_diastolic_max': return 119;
      default: return 0;
    }
  }

  @override
  String getString(String key) {
    switch (key) {
      case 'str_app_name': return 'BP Monitor';
      case 'str_app_description': return 'Monitor de Pressão Arterial';
      case 'str_login_with_google': return 'Entrar com Google';
      case 'str_login_canceled': return 'Login cancelado';
      case 'str_login_error': return 'Erro no login';
      case 'str_unauthenticated': return 'Não autenticado';
      case 'str_sync_complete': return 'Sincronização completa';
      case 'str_optimal_category': return 'Ótima';
      case 'str_normal_category': return 'Normal';
      case 'str_elevated_category': return 'Elevada';
      case 'str_high_stage1_category': return 'Alta Estágio 1';
      case 'str_high_stage2_category': return 'Alta Estágio 2';
      case 'str_crisis_category': return 'Crise Hipertensiva';
      case 'str_nav_home': return 'Início';
      case 'str_nav_history': return 'Histórico';
      case 'str_nav_statistics': return 'Estatísticas';
      case 'str_nav_profile': return 'Perfil';
      case 'str_nav_add_measurement': return 'Nova Medição';
      case 'str_ui_no_measurements': return 'Nenhuma medição registrada';
      case 'str_ui_last_measurements': return 'Últimas Medições';
      case 'str_ui_view_all': return 'Ver todas';
      case 'str_ui_try_again': return 'Tentar novamente';
      case 'str_version': return 'Versão 1.0.0';
      default: return '';
    }
  }

  @override
  bool getBool(String key) => true;

  @override
  double getDouble(String key) {
    switch (key) {
      case 'border_radius': return 12.0;
      case 'card_padding': return 16.0;
      default: return 12.0;
    }
  }

  @override
  Color getColor(String key) {
    switch (key) {
      case 'primary_color': return const Color(0xFF2563EB);
      case 'secondary_color': return const Color(0xFFDC2626);
      case 'background_color': return const Color(0xFFF9FAFB);
      case 'card_color': return Colors.white;
      case 'text_primary_color': return const Color(0xFF1F2937);
      case 'text_secondary_color': return const Color(0xFF6B7280);
      case 'optimal_color': return const Color(0xFF10B981);
      case 'normal_color': return const Color(0xFF3B82F6);
      case 'elevated_color': return const Color(0xFFF59E0B);
      case 'high_stage1_color': return const Color(0xFFEF4444);
      case 'high_stage2_color': return const Color(0xFFDC2626);
      case 'crisis_color': return const Color(0xFF7C3AED);
      default: return Colors.blue;
    }
  }

  @override
  Future<bool> forceRefresh() async => true;
}