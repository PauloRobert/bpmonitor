// main.dart (CORRIGIDO)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bp_monitor/core/di/injection_container.dart' as di;
import 'package:bp_monitor/core/sync/sync_service.dart';
import 'package:bp_monitor/core/remote_config/remote_config_service.dart';
import 'package:bp_monitor/presentation/app.dart';
import 'package:bp_monitor/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar injeção de dependências
  await di.init();

  // Iniciar sincronização periódica
  final remoteConfig = di.sl<RemoteConfigService>();
  final syncInterval = Duration(minutes: remoteConfig.getInt('sync_interval_minutes'));
  di.sl<SyncService>().startPeriodicSync();

  runApp(const BPMonitorApp());
}