import 'package:bp_monitor/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String birthDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? email;

  UserModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.email,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      birthDate: entity.birthDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      photoUrl: entity.photoUrl,
      email: entity.email,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      birthDate: birthDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photoUrl: photoUrl,
      email: email,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      birthDate: data['birthDate'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      photoUrl: data['photoUrl'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photoUrl': photoUrl,
      'email': email,
    };
  }
}