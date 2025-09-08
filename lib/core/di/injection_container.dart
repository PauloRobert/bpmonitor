import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/core/network/network_info.dart';
import 'package:bp_monitor/core/local/hive_setup.dart';
import 'package:bp_monitor/data/datasources/local/measurement_local_datasource.dart';
import 'package:bp_monitor/data/repositories/auth_repository_impl.dart';
import 'package:bp_monitor/data/repositories/measurement_repository_impl.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';
import 'package:bp_monitor/domain/repositories/measurement_repository.dart';
import 'package:bp_monitor/domain/usecases/get_pressure_category.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Registrar componentes externos
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<GoogleSignIn>(GoogleSignIn());
  sl.registerSingleton<InternetConnectionChecker>(InternetConnectionChecker());

  // Core
  final logger = AppLoggerImpl();
  sl.registerSingleton<AppLogger>(logger);

  // Inicializar Hive
  await HiveSetup.initialize(logger);

  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  // Remote Config
  final remoteConfig = await RemoteConfigService.getInstance();
  sl.registerSingleton<RemoteConfigService>(remoteConfig);

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

  // BLoCs
  _registerBlocs();
}

void _registerRepositories() {
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
      logger: sl(),
    ),
  );

  sl.registerLazySingleton<MeasurementRepository>(
        () => MeasurementRepositoryImpl(
      firestore: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
      auth: sl(),
    ),
  );
}

void _registerUseCases() {
  sl.registerLazySingleton(() => GetPressureCategory(remoteConfig: sl()));
}

void _registerBlocs() {
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
}