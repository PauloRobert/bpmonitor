import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../shared/models/user_model.dart';
// FIX: Importar o AppRouter para usar as rotas nomeadas
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
  // A GlobalKey não é mais necessária, vamos usar a abordagem moderna
  // final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
        // FIX: Também é preciso parar o loading aqui
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _dbHelper.insertUser(user);

      AppConstants.logInfo('Onboarding concluído para usuário: ${user.name}');

      // FIX: Navega ANTES de mudar o estado, se o widget ainda estiver montado.
      if (mounted) {
        _navigateToHome();
      }

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao completar onboarding', e, stackTrace);
      _showError('Erro ao salvar dados. Tente novamente.');
      // FIX: Garante que o loading para mesmo em caso de erro.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    // NOTA: Não colocamos o setState(isLoading=false) aqui no sucesso,
    // porque a tela será destruída pela navegação. Se a navegação falhasse,
    // o ideal seria ter um `finally` ou parar o loading após a navegação.
    // Como estamos substituindo a tela, não é um problema crítico.
  }

  void _showError(String message) {
    // FIX: Usar a abordagem moderna para SnackBar, que é mais segura.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.secondaryColor,
        ),
      );
    }
  }

  void _navigateToHome() {
    AppConstants.logNavigation('OnboardingScreen', 'MainNavigation');
    // FIX: Implementar a navegação usando a rota definida no AppRouter.
    // Usamos pushReplacementNamed para que o usuário não possa "voltar" para o onboarding.
    Navigator.of(context).pushReplacementNamed(AppRouter.main);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key não é mais necessária
      backgroundColor: AppConstants.backgroundColor,
      // Usar um GestureDetector para esconder o teclado ao tocar fora dos campos
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

  // ... O resto do seu arquivo (os métodos _build) pode continuar exatamente igual ...
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
                hintText: 'Digite seu nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: 'Data de nascimento *',
                hintText: 'Selecione sua data de nascimento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectBirthDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage >= AppConstants.onboardingData.length;
    final isFirstPage = _currentPage == 0;

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
                  onPressed: _previousPage,
                  child: const Text('Anterior'),
                ),
              const Spacer(),
              if (isLastPage)
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeOnboarding,
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