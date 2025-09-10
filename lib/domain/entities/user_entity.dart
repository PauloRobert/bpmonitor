import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String birthDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? email;

  const UserEntity({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.email,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? photoUrl,
    String? email,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }

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

  @override
  List<Object?> get props => [
    id,
    name,
    birthDate,
    createdAt,
    updatedAt,
    photoUrl,
    email,
  ];
}