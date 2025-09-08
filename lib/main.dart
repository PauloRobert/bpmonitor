import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bp_monitor/core/di/injection_container.dart' as di;
import 'package:bp_monitor/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar Hive
  await Hive.initFlutter();

  // Inicializar injeção de dependências
  await di.init();

  runApp(const BPMonitorApp());
}