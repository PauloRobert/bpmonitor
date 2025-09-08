import 'package:hive_flutter/hive_flutter.dart';
import 'package:bp_monitor/core/utils/logger.dart';

class HiveSetup {
  static const String measurementsBoxName = 'measurements';
  static const String syncFlagsBoxName = 'sync_flags';
  static const String deletionFlagsBoxName = 'deletion_flags';
  static const String settingsBoxName = 'settings';

  static Future<void> initialize(AppLogger logger) async {
    try {
      await Hive.initFlutter();

      // Abrir boxes
      await Hive.openBox<Map>(measurementsBoxName);
      await Hive.openBox<bool>(syncFlagsBoxName);
      await Hive.openBox<bool>(deletionFlagsBoxName);
      await Hive.openBox(settingsBoxName);

      logger.i('Hive inicializado com sucesso');
    } catch (e) {
      logger.e('Erro ao inicializar Hive', e);
      rethrow;
    }
  }

  static Box<Map> getMeasurementsBox() {
    return Hive.box<Map>(measurementsBoxName);
  }

  static Box<bool> getSyncFlagsBox() {
    return Hive.box<bool>(syncFlagsBoxName);
  }

  static Box<bool> getDeletionFlagsBox() {
    return Hive.box<bool>(deletionFlagsBoxName);
  }

  static Box getSettingsBox() {
    return Hive.box(settingsBoxName);
  }
}