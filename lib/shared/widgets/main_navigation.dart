import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../features/home/home_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/measurements/add_measurement_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/reports_screen.dart'; // ✅ IMPORTAÇÃO CORRIGIDA

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  // No MainNavigation, adicione este metodo público:
  static void navigateToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<State<MainNavigation>>();
    if (state != null && state is _MainNavigationState) {
      state._onTabSelected(tabIndex);
    }
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final GlobalKey<State<HomeScreen>> _homeKey = GlobalKey<State<HomeScreen>>();
  final GlobalKey<State<HistoryScreen>> _historyKey = GlobalKey<State<HistoryScreen>>();

  late final List<Widget> _screens;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      HistoryScreen(key: _historyKey),
      const ReportsScreen(), // ✅ USA A NOVA TELA DE RELATÓRIOS
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }




  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined, // ✅ ÍCONE CORRIGIDO
      activeIcon: Icons.home,
      label: 'Hoje',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Histórico',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined, // ✅ ÍCONE CORRIGIDO PARA RELATÓRIOS
      activeIcon: Icons.analytics,
      label: 'Relatórios',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);

      try {
        AppConstants.logNavigation(
          _navigationItems[_currentIndex].label,
          _navigationItems[index].label,
        );
      } catch (e) {
        debugPrint('Erro ao logar navegação: $e');
      }
    }
  }

  void _onAddPressed() async {
    try {
      AppConstants.logNavigation('MainNavigation', 'AddMeasurementScreen');
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddMeasurementScreen(),
        ),
      );

      if (result == true) {
        // ✅ MELHORADO: Refresh mais inteligente baseado na aba atual
        if (_currentIndex == 0) {
          // Home tab
          final homeState = _homeKey.currentState;
          if (homeState is HomeScreenController) {
            (homeState as HomeScreenController).refreshData();
          }
        }

        // Sempre refresh do histórico quando uma medição é adicionada
        final historyState = _historyKey.currentState;
        if (historyState is HistoryScreenController) {
          (historyState as HistoryScreenController).loadMeasurements();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Medição adicionada!', style: TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: AppConstants.successColor, // ✅ USA CONSTANTE
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _currentIndex = 1; // Ir para aba de histórico
                  });
                  _pageController.jumpToPage(1);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao adicionar medição: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro: Não foi possível adicionar a medição.'),
              ],
            ),
            backgroundColor: AppConstants.dangerColor, // ✅ USA CONSTANTE
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 10,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0),
          _buildNavItem(1),
          const SizedBox(width: 48), // Espaço para o FAB
          _buildNavItem(2),
          _buildNavItem(3),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navigationItems[index];
    final isActive = index == _currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12), // ✅ MELHORADO: Borda arredondada
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // ✅ MELHORADO: Animação suave
          height: 60,
          decoration: isActive
              ? BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  key: ValueKey(isActive),
                  color: isActive ? AppConstants.primaryColor : AppConstants.textSecondary,
                  size: isActive ? 26 : 24, // ✅ MELHORADO: Tamanho dinâmico
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isActive ? 12 : 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppConstants.primaryColor : AppConstants.textSecondary,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // ✅ MELHORADO: Animação
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppConstants.logoGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3), // ✅ CORRIGIDO: withValues
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onAddPressed,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _currentIndex == 0 ? 0 : 0.125, // ✅ MELHORADO: Pequena rotação
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}


abstract class HomeScreenController {
  void refreshData();
}

abstract class HistoryScreenController {
  void loadMeasurements();
}