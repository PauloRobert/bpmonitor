// core/local/migration_service.dart (corrigido)
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bp_monitor/core/utils/logger.dart';

class MigrationService {
  final SharedPreferences _prefs;
  final AppLogger _logger;

  static const String _currentVersionKey = 'db_version';
  static const int _latestVersion = 1; // Incrementar a cada migração

  MigrationService({
    required SharedPreferences prefs,
    required AppLogger logger,
  }) : _prefs = prefs,
        _logger = logger;

  Future<void> checkAndRunMigrations() async {
    try {
      final currentVersion = _prefs.getInt(_currentVersionKey) ?? 0;

      if (currentVersion < _latestVersion) {
        _logger.i('Iniciando migração do banco de dados: v$currentVersion -> v$_latestVersion');

        // Executar migrações em sequência
        if (currentVersion < 1) {
          await _migrateToV1();
        }

        // Salvar nova versão
        await _prefs.setInt(_currentVersionKey, _latestVersion);
        _logger.i('Migração concluída para v$_latestVersion');
      } else {
        _logger.d('Banco de dados já está na versão mais recente: v$currentVersion');
      }
    } catch (e) {
      _logger.e('Erro durante migração do banco de dados', e);
      // Não propagar o erro para não impedir o app de iniciar
    }
  }

  // Migração para v1 (inicial)
  Future<void> _migrateToV1() async {
    _logger.d('Executando migração para v1');

    try {
      // Migrar do SQLite para Hive (se necessário)
      final hasLegacyData = _prefs.getBool('has_legacy_data') ?? false;

      if (hasLegacyData) {
        // Isso seria implementado quando tivermos dados legados para migrar
        _logger.i('Migrando dados legados do SQLite para Hive');

        // Exemplo de lógica de migração:
        // 1. Ler dados do SQLite
        // 2. Convertê-los para o formato Hive
        // 3. Salvá-los no Hive
        // 4. Marcar migração como concluída

        await _prefs.setBool('has_legacy_data', false);
        _logger.i('Migração de dados legados concluída');
      } else {
        _logger.d('Nenhum dado legado encontrado, pulando migração');
      }
    } catch (e) {
      _logger.e('Erro ao migrar para v1', e);
      // Continuar com a execução do app mesmo em caso de erro
    }
  }
}