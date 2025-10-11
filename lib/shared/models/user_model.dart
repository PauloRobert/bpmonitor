import '../../core/constants/app_constants.dart';

/// Modelo de dados do usuário - ATUALIZADO COM NOVOS CAMPOS
class UserModel {
  final int? id;
  final String name;
  final String birthDate;
  final String gender;      // ✅ NOVO: 'M' ou 'F'
  final double weight;      // ✅ NOVO: peso em kg (1 decimal)
  final double height;      // ✅ NOVO: altura em metros (2 decimais)
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
        gender = 'M',
        weight = 70.0,
        height = 1.70,
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

  /// ✅ NOVO: Getter para nome do sexo
  String get genderName => AppConstants.genderOptions[gender] ?? 'Não informado';

  /// ✅ NOVO: Getter para peso formatado
  String get weightFormatted => '${weight.toStringAsFixed(1)} kg';

  /// ✅ NOVO: Getter para altura formatada
  String get heightFormatted => '${height.toStringAsFixed(2)} m';

  /// ✅ NOVO: Getter para IMC
  double get bmi => AppConstants.calculateBMI(weight, height);

  /// ✅ NOVO: Getter para categoria do IMC
  String get bmiCategory => AppConstants.getBMICategory(bmi);

  /// ✅ NOVO: Getter para IMC formatado
  String get bmiFormatted => '${bmi.toStringAsFixed(1)} - $bmiCategory';

  /// Verifica se os dados do usuário estão válidos
  bool get isValid {
    final nameValid = name.trim().isNotEmpty;
    final birthDateValid = birthDate.isNotEmpty;
    final ageValid = age >= 10 && age <= 120;
    final genderValid = AppConstants.genderOptions.containsKey(gender);
    final weightValid = weight >= AppConstants.minWeight && weight <= AppConstants.maxWeight;
    final heightValid = height >= AppConstants.minHeight && height <= AppConstants.maxHeight;

    AppConstants.logInfo(
        'Validação do usuário: name=$nameValid, birthDate=$birthDateValid, age=$ageValid, '
            'gender=$genderValid, weight=$weightValid, height=$heightValid');

    return nameValid && birthDateValid && ageValid && genderValid && weightValid && heightValid;
  }

  /// Converte de Map para UserModel (vindo do database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      AppConstants.logDatabase('fromMap', 'users', 'Converting map to UserModel');

      return UserModel(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        birthDate: map['birth_date'] as String? ?? '',
        gender: map['gender'] as String? ?? 'M',
        weight: (map['weight'] as num?)?.toDouble() ?? 70.0,
        height: (map['height'] as num?)?.toDouble() ?? 1.70,
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
        'gender': gender,
        'weight': weight,
        'height': height,
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
    String? gender,
    double? weight,
    double? height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    AppConstants.logInfo('Criando cópia do usuário com alterações');

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

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, birthDate: $birthDate, age: $age, '
        'gender: $genderName, weight: $weightFormatted, height: $heightFormatted, '
        'bmi: $bmiFormatted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.weight == weight &&
        other.height == height &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    birthDate.hashCode ^
    gender.hashCode ^
    weight.hashCode ^
    height.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;
  }
}