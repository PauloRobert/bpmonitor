/// ============================================================================
/// UserDao
/// ============================================================================
/// - Responsável por todas as operações de CRUD relacionadas à tabela `users`.
/// - Contém apenas as queries específicas para `UserModel`.
/// - Mantém regras de integridade (ex: nome não vazio).
/// - Isola a lógica de acesso a dados do restante do app.
/// ============================================================================
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';

class UserDao {
  final Database db;
  UserDao(this.db);

  Future<int> insert(UserModel user) async {
    if (user.name.isEmpty) {
      throw ArgumentError('Nome do usuário não pode ser vazio');
    }
    return await db.insert(AppConstants.usersTable, user.toMap());
  }

  Future<UserModel?> getLastUser() async {
    final maps = await db.query(
      AppConstants.usersTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  Future<int> update(UserModel user) async {
    return await db.update(
      AppConstants.usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteAll() async {
    return await db.delete(AppConstants.usersTable);
  }
}