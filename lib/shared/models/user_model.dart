import '../../core/constants/app_constants.dart';

/// Modelo de dados do usuário
class UserModel {
  final int? id;
  final String name;
  final String birthDate; // armazenado como String (ISO8601 ou "yyyy-MM-dd")
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Construtor para criar usuário vazio
  UserModel.empty()
      : id = null,
        name = '',
        birthDate = '',
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Getter que retorna a data de nascimento como DateTime
  DateTime? get birthDateAsDateTime {
    try {
      if (birthDate.isEmpty) return null;
      return DateTime.parse(birthDate);
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao converter birthDate para DateTime', e, stackTrace);
      return null;
    }
  }

  /// Calcula a idade baseada na data de nascimento
  int get age {
    try {
      final birth = birthDateAsDateTime;
      if (birth == null) {
        AppConstants.logWarning('Tentativa de calcular idade com birthDate inválido ou vazio');
        return 0;
      }

      final today = DateTime.now();
      int calculatedAge = today.year - birth.year;

      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        calculatedAge--;
      }

      AppConstants.logInfo('Idade calculada: $calculatedAge anos para nascimento em $birthDate');
      return calculatedAge;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao calcular idade', e, stackTrace);
      return 0;
    }
  }

  /// Verifica se os dados do usuário estão válidos
  bool get isValid {
    final nameValid = name.trim().isNotEmpty;
    final birthDateValid = birthDate.isNotEmpty;
    final ageValid = age >= 10 && age <= 120;

    AppConstants.logInfo(
        'Validação do usuário: name=$nameValid, birthDate=$birthDateValid, age=$ageValid (${age} anos)');

    return nameValid && birthDateValid && ageValid;
  }

  /// Converte de Map para UserModel (vindo do database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      AppConstants.logDatabase('fromMap', 'users', 'Converting map to UserModel');

      return UserModel(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        birthDate: map['birth_date'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao converter Map para UserModel', e, stackTrace);
      rethrow;
    }
  }

  /// Converte de UserModel para Map (para salvar no database)
  Map<String, dynamic> toMap() {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'birth_date': birthDate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

      if (id != null) {
        map['id'] = id!;
      }

      AppConstants.logDatabase('toMap', 'users', 'Converting UserModel to map');
      return map;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao converter UserModel para Map', e, stackTrace);
      rethrow;
    }
  }

  /// Cria uma cópia do usuário com campos atualizados
  UserModel copyWith({
    int? id,
    String? name,
    String? birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    AppConstants.logInfo('Criando cópia do usuário com alterações');

    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Sempre atualiza updatedAt
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, birthDate: $birthDate, age: $age, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    birthDate.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;
  }
}