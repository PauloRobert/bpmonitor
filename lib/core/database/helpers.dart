/// ============================================================================
/// Helpers
/// ============================================================================
/// - Funções utilitárias para lidar com:
///   • Sincronização (mutex) => evita race conditions na inicialização do DB.
///   • Inserções em batch (mais performáticas).
///   • Transações seguras.
///   • Verificação de colunas (usado em migrations).
/// - Isola lógica genérica de manipulação do banco que não pertence a um DAO.
/// ============================================================================
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class _SimpleLock {
  Future<void> _head = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _head = _head.then((_) {
      final futureAction = Future<T>.sync(action);
      futureAction
          .then((value) => completer.complete(value))
          .catchError((e, st) => completer.completeError(e, st));
      return futureAction.then((_) => null);
    });
    return completer.future;
  }
}

final Map<Object, _SimpleLock> _locks = {};

Future<T> synchronized<T>(Object lock, Future<T> Function() action) =>
    (_locks.putIfAbsent(lock, () => _SimpleLock())).synchronized(action);

Future<void> batchInsert(Database db, String table, Iterable<Map<String, Object?>> records,
    {bool noResult = true}) async {
  if (records.isEmpty) return;
  final batch = db.batch();
  for (final map in records) {
    batch.insert(table, map);
  }
  await batch.commit(noResult: noResult);
}

Future<T> runInTransaction<T>(Database db, Future<T> Function(Transaction txn) action) =>
    db.transaction(action);

Future<bool> columnExists(DatabaseExecutor db, String tableName, String columnName) async {
  try {
    final info = await db.rawQuery("PRAGMA table_info('$tableName')");
    return info.any((row) => row['name'] == columnName);
  } catch (e, st) {
    AppConstants.logError('Erro ao verificar coluna $columnName em $tableName', e, st);
    rethrow;
  }
}