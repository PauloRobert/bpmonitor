import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../features/home/home_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/measurements/add_measurement_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // ✅ FIX: Usar GlobalKey com interfaces públicas
  final GlobalKey<State<HomeScreen>> _homeKey = GlobalKey<State<HomeScreen>>();
  final GlobalKey<State<HistoryScreen>> _historyKey = GlobalKey<State<HistoryScreen>>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      HistoryScreen(key: _historyKey),
      const ReportsScreen(),
    ];
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
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
  ];

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      AppConstants.logNavigation(
        _navigationItems[_currentIndex].label,
        _navigationItems[index].label,
      );
    }
  }

  // ✅ FIX: Implementar corretamente o FAB com refresh das telas usando interfaces
  void _onAddPressed() async {
    AppConstants.logNavigation('MainNavigation', 'AddMeasurementScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddMeasurementScreen(),
      ),
    );

    // ✅ FIX: Se uma medição foi salva, atualiza as telas relevantes
    if (result == true) {
      // Atualiza a HomeScreen se estiver na aba Home
      if (_currentIndex == 0) {
        final homeState = _homeKey.currentState;
        if (homeState is HomeScreenController) {
          (homeState as HomeScreenController).refreshData();
        }
      }

      // Sempre atualiza o histórico quando uma medição é adicionada
      final historyState = _historyKey.currentState;
      if (historyState is HistoryScreenController) {
        (historyState as HistoryScreenController).loadMeasurements();
      }

      // Mostra feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Dados atualizados!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _navigationItems.length; i++) ...[
                if (i == 1) const SizedBox(width: 60), // Espaço para FAB
                _buildNavItem(i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navigationItems[index];
    final isActive = index == _currentIndex;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive
                  ? AppConstants.primaryColor
                  : AppConstants.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 60,
      height: 60,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onAddPressed,
          borderRadius: BorderRadius.circular(30),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
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

// Placeholder para a tela de relatórios
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