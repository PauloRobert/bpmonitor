import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../features/home/home_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/measurements/add_measurement_screen.dart';
import '../../features/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

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
      const ReportsScreen(),
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
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: 'Hoje',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Histórico',
    ),
    NavigationItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
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
        if (_currentIndex == 0) {
          final homeState = _homeKey.currentState;
          if (homeState is HomeScreenController) {
            (homeState as HomeScreenController).refreshData();
          }
        }
        final historyState = _historyKey.currentState;
        if (historyState is HistoryScreenController) {
          (historyState as HistoryScreenController).loadMeasurements();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Dados atualizados!', style: TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao adicionar medição: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: Não foi possível adicionar a medição.'),
            backgroundColor: Colors.red,
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
          const SizedBox(width: 48),
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
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? AppConstants.primaryColor : AppConstants.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppConstants.primaryColor : AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppConstants.logoGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _onAddPressed,
        borderRadius: BorderRadius.circular(30),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
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

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppConstants.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Relatórios em desenvolvimento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Em breve você poderá gerar relatórios em PDF para compartilhar com seu médico',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class HomeScreenController {
  void refreshData();
}

abstract class HistoryScreenController {
  void loadMeasurements();
}