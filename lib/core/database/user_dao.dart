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

  /// Insere um novo usuário
  Future<int> insert(UserModel user) async {
    if (user.name.isEmpty) {
      throw ArgumentError('Nome do usuário não pode ser vazio');
    }

    final userToInsert = user.copyWith(
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
    );

    return await db.insert(AppConstants.usersTable, userToInsert.toMap());
  }

  /// Atualiza um usuário existente
  Future<int> update(UserModel user) async {
    final userToUpdate = user.copyWith(updatedAt: DateTime.now());

    return await db.update(
      AppConstants.usersTable,
      userToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Busca o último usuário criado
  Future<UserModel?> getLastUser() async {
    final maps = await db.query(
      AppConstants.usersTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  /// Deleta um usuário por id
  Future<int> delete(int id) async {
    return await db.delete(
      AppConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Limpa todos os usuários da tabela
  Future<void> clear() async {
    await db.delete(AppConstants.usersTable);
  }
}