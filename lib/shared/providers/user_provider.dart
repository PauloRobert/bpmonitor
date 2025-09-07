import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_service.dart';
import '../models/user_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final db = DatabaseService.instance;

  Future<void> _loadUser() async {
    try {
      AppConstants.logInfo('Carregando dados do usuário via provider');
      final user = await db.getUser();
      state = AsyncValue.data(user);
      AppConstants.logInfo('Usuário carregado no provider: ${user?.name ?? "Nenhum usuário"}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar usuário no provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      AppConstants.logInfo('Salvando usuário via provider: ${user.name}');

      if (state.value != null) {
        final updatedUser = user.copyWith(id: state.value!.id);
        await db.updateUser(updatedUser);
        state = AsyncValue.data(updatedUser);
      } else {
        final id = await db.insertUser(user);
        final savedUser = user.copyWith(id: id);
        state = AsyncValue.data(savedUser);
      }

      AppConstants.logInfo('Usuário salvo com sucesso via provider');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao salvar usuário via provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      AppConstants.logInfo('Atualizando usuário via provider: ${user.name}');
      await db.updateUser(user);
      state = AsyncValue.data(user);
      AppConstants.logInfo('Usuário atualizado com sucesso via provider');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao atualizar usuário via provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    AppConstants.logInfo('Atualizando dados do usuário no provider');
    _loadUser();
  }
}