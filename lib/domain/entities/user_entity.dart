import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String birthDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? photoUrl,
    String? email,
  }) = _UserEntity;

  const UserEntity._();

  int get age {
    try {
      if (birthDate.isEmpty) return 0;

      final birth = DateTime.parse(birthDate);
      final today = DateTime.now();
      int calculatedAge = today.year - birth.year;

      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        calculatedAge--;
      }

      return calculatedAge;
    } catch (_) {
      return 0;
    }
  }
}