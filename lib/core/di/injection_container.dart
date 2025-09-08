// core/di/injection_container.dart (completo com todas as correções)
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

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
  final googleSignIn = GoogleSignIn.instance;
// Apenas inicializa, sem scopes
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