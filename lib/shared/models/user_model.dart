import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

/// Modelo de dados do usuário
class UserModel {
  final int? id;
  final String name;
  final String birthDate;
  final String gender;
  final double weight;
  final double height;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.weight,
    required this.height,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Construtor para criar usuário vazio
  UserModel.empty()
      : id = null,
        name = '',
        birthDate = '',
        gender = '',
        weight = 0.0,
        height = 0.0,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  // ============================================================
  //  TRATAMENTO SEGURO DE DATA DE NASCIMENTO
  // ============================================================

  /// Converte birthDate (dd/MM/yyyy) para DateTime com tratamento completo de erro
  DateTime? get birthDateAsDateTime {
    if (birthDate.trim().isEmpty) {
      AppConstants.logWarning('[UserModel] birthDate vazio');
      return null;
    }

    try {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.parseStrict(birthDate);
    } catch (e, stack) {
      AppConstants.logError(
        '[UserModel] Falha ao converter birthDate="$birthDate"',
        e,
        stack,
      );
      return null;
    }
  }

  // ============================================================
  //  CÁLCULO DE IDADE (COM FALHA CONTROLADA)
  // ============================================================

  int get age {
    try {
      final birth = birthDateAsDateTime;
      if (birth == null) {
        AppConstants.logWarning(
          '[UserModel] Tentativa de calcular idade com birthDate inválido',
        );
        return 0;
      }

      final today = DateTime.now();
      int years = today.year - birth.year;

      final beforeBirthday = today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day);

      if (beforeBirthday) years--;

      if (years < 0 || years > 150) {
        AppConstants.logWarning(
          '[UserModel] Idade calculada fora do esperado: $years',
        );
        return 0;
      }

      return years;
    } catch (e, stack) {
      AppConstants.logError('[UserModel] Erro ao calcular idade', e, stack);
      return 0;
    }
  }

  // ============================================================
  //  GETTERS AUXILIARES
  // ============================================================

  String get genderName => AppConstants.genderOptions[gender] ?? 'Não informado';
  String get weightFormatted => '${weight.toStringAsFixed(1)} kg';
  String get heightFormatted => '${height.toStringAsFixed(2)} m';

  double get bmi => AppConstants.calculateBMI(weight, height);

  String get bmiCategory => AppConstants.getBMICategory(bmi);

  String get bmiFormatted => '${bmi.toStringAsFixed(1)} - $bmiCategory';

  // ============================================================
  //  VALIDAÇÃO DO USUÁRIO
  // ============================================================

  bool get isValid {
    final nameValid = name.trim().isNotEmpty;
    final dateValid = birthDateAsDateTime != null;
    final ageValid = age >= 10 && age <= 120;
    final genderValid = AppConstants.genderOptions.containsKey(gender);
    final weightValid =
        weight >= AppConstants.minWeight && weight <= AppConstants.maxWeight;
    final heightValid =
        height >= AppConstants.minHeight && height <= AppConstants.maxHeight;

    AppConstants.logInfo(
      '[UserModel] Valid: '
          'name=$nameValid, date=$dateValid, age=$ageValid, '
          'gender=$genderValid, weight=$weightValid, height=$heightValid',
    );

    return nameValid &&
        dateValid &&
        ageValid &&
        genderValid &&
        weightValid &&
        heightValid;
  }

  // ============================================================
  //  SERIALIZAÇÃO
  // ============================================================

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        birthDate: map['birth_date'] as String? ?? '',
        gender: map['gender'] as String? ?? '',
        weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
        height: (map['height'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e, stack) {
      AppConstants.logError(
        '[UserModel] Erro ao converter Map -> UserModel',
        e,
        stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        if (id != null) 'id': id,
        'name': name,
        'birth_date': birthDate,
        'gender': gender,
        'weight': weight,
        'height': height,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
    } catch (e, stack) {
      AppConstants.logError(
        '[UserModel] Erro ao converter UserModel -> Map',
        e,
        stack,
      );
      rethrow;
    }
  }

  // ============================================================
  //  COPYWITH
  // ============================================================

  UserModel copyWith({
    int? id,
    String? name,
    String? birthDate,
    String? gender,
    double? weight,
    double? height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  //  OVERRIDES
  // ============================================================

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, birthDate: $birthDate, age: $age, '
        'gender: $genderName, weight: $weightFormatted, height: $heightFormatted, '
        'bmi: $bmiFormatted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      birthDate.hashCode ^
      gender.hashCode ^
      weight.hashCode ^
      height.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is UserModel &&
              other.id == id &&
              other.name == name &&
              other.birthDate == birthDate &&
              other.gender == gender &&
              other.weight == weight &&
              other.height == height &&
              other.createdAt == createdAt &&
              other.updatedAt == updatedAt);
}