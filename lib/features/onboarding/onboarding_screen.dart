import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
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

  int _currentPage = 0;
  bool _isLoading = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
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

  // ✅ FIX: Implementação completa do onboarding com SharedPreferences
  Future<void> _completeOnboarding() async {
    // Esconde o teclado se estiver aberto
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showError(AppConstants.validationNameError);
      return;
    }

    if (_birthDateController.text.isEmpty) {
      _showError(AppConstants.validationBirthDateError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel(
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text,
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

      // ✅ FIX: Salvar usuário no database
      await _dbHelper.insertUser(user);
      AppConstants.logInfo('Usuário salvo: ${user.name}, ${user.age} anos');

      // ✅ FIX: CRÍTICO - Marcar onboarding como concluído
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.onboardingCompleteKey, true);
      AppConstants.logInfo('Onboarding marcado como concluído');

      AppConstants.logUserAction('complete_onboarding', {
        'userName': user.name,
        'userAge': user.age,
      });

      // Navegar para home se o widget ainda estiver montado
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
            // ✅ FIX: Melhorar validação em tempo real
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
            // ✅ FIX: Mostrar idade calculada
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
          ],
        ),
      ),
    );
  }

  // ✅ FIX: Método para calcular idade em tempo real
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

  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage >= AppConstants.onboardingData.length;
    final isFirstPage = _currentPage == 0;
    final canProceed = isLastPage
        ? _nameController.text.trim().isNotEmpty &&
        _birthDateController.text.isNotEmpty &&
        _getAgeFromBirthDate() >= 10
        : true;

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