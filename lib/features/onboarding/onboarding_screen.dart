import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import '../../utils/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  int _currentPage = 0;
  bool _isLoading = false;
  String _selectedGender = 'M'; // ✅ NOVO: Sexo selecionado

  final db = DatabaseService.instance;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < AppConstants.onboardingData.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _completeOnboarding() async {
    FocusScope.of(context).unfocus();

    // Validações
    if (_nameController.text.trim().isEmpty) {
      _showError(AppConstants.validationNameError);
      return;
    }

    if (_birthDateController.text.isEmpty) {
      _showError(AppConstants.validationBirthDateError);
      return;
    }

    // ✅ NOVO: Validação de peso
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null) {
      _showError(AppConstants.validationWeightError);
      return;
    }
    if (weight < AppConstants.minWeight || weight > AppConstants.maxWeight) {
      _showError(AppConstants.validationWeightRangeError);
      return;
    }

    // ✅ NOVO: Validação de altura
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (height == null) {
      _showError(AppConstants.validationHeightError);
      return;
    }
    if (height < AppConstants.minHeight || height > AppConstants.maxHeight) {
      _showError(AppConstants.validationHeightRangeError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel(
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text,
        gender: _selectedGender,
        weight: weight,
        height: height,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!user.isValid) {
        _showError(AppConstants.validationAgeError);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await db.insertUser(user);
      AppConstants.logInfo('Usuário salvo: ${user.name}, ${user.age} anos, ${user.genderName}, '
          '${user.weightFormatted}, ${user.heightFormatted}, IMC: ${user.bmiFormatted}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.onboardingCompleteKey, true);
      AppConstants.logInfo('Onboarding marcado como concluído');

      AppConstants.logUserAction('complete_onboarding', {
        'userName': user.name,
        'userAge': user.age,
        'gender': user.gender,
        'bmi': user.bmi.toStringAsFixed(1),
      });

      if (mounted) {
        _navigateToHome();
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao completar onboarding', e, stackTrace);
      _showError('Erro ao salvar dados. Tente novamente.');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.secondaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToHome() {
    AppConstants.logNavigation('OnboardingScreen', 'MainNavigation');
    Navigator.of(context).pushReplacementNamed(AppRouter.main);
  }

  int _getAgeFromBirthDate() {
    if (_birthDateController.text.isEmpty) return 0;

    try {
      final birth = DateTime.parse(_birthDateController.text);
      final today = DateTime.now();
      int age = today.year - birth.year;

      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: AppConstants.onboardingData.length + 1,
                  itemBuilder: (context, index) {
                    if (index < AppConstants.onboardingData.length) {
                      return _buildOnboardingPage(AppConstants.onboardingData[index]);
                    } else {
                      return _buildUserDataPage();
                    }
                  },
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppConstants.logoGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['icon'],
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data['title'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            data['content'],
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserDataPage() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 32),
            const Text(
              'Vamos nos conhecer melhor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Esses dados nos ajudarão a personalizar seus relatórios',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Nome
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome completo *',
                hintText: 'Digite seu nome',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                errorText: _nameController.text.isNotEmpty && _nameController.text.trim().length < 2
                    ? 'Nome muito curto'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Data de nascimento
            TextField(
              controller: _birthDateController,
              decoration: InputDecoration(
                labelText: 'Data de nascimento *',
                hintText: 'Selecione sua data de nascimento',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.cake),
                suffixIcon: const Icon(Icons.calendar_today),
                errorText: _birthDateController.text.isNotEmpty && _getAgeFromBirthDate() < 10
                    ? 'Idade mínima: 10 anos'
                    : null,
              ),
              readOnly: true,
              onTap: _selectBirthDate,
            ),

            if (_birthDateController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Idade: ${_getAgeFromBirthDate()} anos',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ✅ NOVO: Seletor de sexo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wc, color: AppConstants.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Sexo *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderOption('M', Icons.male),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderOption('F', Icons.female),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ NOVO: Peso
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg) *',
                hintText: 'Ex: 70,5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Substitui ponto por vírgula
                  String text = newValue.text.replaceAll('.', ',');
                  // Permite apenas uma vírgula
                  if (text.split(',').length > 2) {
                    return oldValue;
                  }
                  // Limita decimais a 1 casa
                  if (text.contains(',')) {
                    final parts = text.split(',');
                    if (parts[1].length > 1) {
                      text = '${parts[0]},${parts[1].substring(0, 1)}';
                    }
                  }
                  return TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // ✅ NOVO: Altura
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Altura (m) *',
                hintText: 'Ex: 1,75',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
                suffixText: 'm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  String text = newValue.text.replaceAll('.', ',');
                  if (text.split(',').length > 2) {
                    return oldValue;
                  }
                  // Limita decimais a 2 casas
                  if (text.contains(',')) {
                    final parts = text.split(',');
                    if (parts[1].length > 2) {
                      text = '${parts[0]},${parts[1].substring(0, 2)}';
                    }
                  }
                  return TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              onChanged: (_) => setState(() {}),
            ),

            // ✅ NOVO: Preview do IMC
            if (_weightController.text.isNotEmpty && _heightController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildBMIPreview(),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ NOVO: Widget para opção de sexo
  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    final genderName = AppConstants.genderOptions[gender]!;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              genderName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOVO: Preview do IMC
  Widget _buildBMIPreview() {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

    if (weight == null || height == null || height <= 0) {
      return const SizedBox.shrink();
    }

    final bmi = AppConstants.calculateBMI(weight, height);
    final category = AppConstants.getBMICategory(bmi);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 20,
            color: AppConstants.successColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu IMC',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                Text(
                  '${bmi.toStringAsFixed(1)} - $category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage >= AppConstants.onboardingData.length;
    final isFirstPage = _currentPage == 0;

    bool canProceed = true;
    if (isLastPage) {
      final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
      final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

      canProceed = _nameController.text.trim().isNotEmpty &&
          _birthDateController.text.isNotEmpty &&
          _getAgeFromBirthDate() >= 10 &&
          weight != null &&
          weight >= AppConstants.minWeight &&
          weight <= AppConstants.maxWeight &&
          height != null &&
          height >= AppConstants.minHeight &&
          height <= AppConstants.maxHeight;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLastPage) _buildPageIndicator(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isFirstPage)
                TextButton(
                  onPressed: _isLoading ? null : _previousPage,
                  child: const Text('Anterior'),
                ),
              const Spacer(),
              if (isLastPage)
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !canProceed) ? null : _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Começar'),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Próximo'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        AppConstants.onboardingData.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppConstants.primaryColor
                : AppConstants.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}