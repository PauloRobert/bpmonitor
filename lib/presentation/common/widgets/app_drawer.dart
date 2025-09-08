import 'package:flutter/material.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/core/di/injection_container.dart';
import 'package:bp_monitor/core/theme/app_theme.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = sl<AppStrings>();
    final AppTheme theme = sl<AppTheme>();

    return Drawer(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, strings, theme),
            _buildMenuItem(
              context,
              icon: Icons.home,
              title: strings.home,
              route: AppConstants.homeRoute,
              isSelected: currentRoute == AppConstants.homeRoute,
              theme: theme,
            ),
            _buildMenuItem(
              context,
              icon: Icons.history,
              title: strings.history,
              route: AppConstants.historyRoute,
              isSelected: currentRoute == AppConstants.historyRoute,
              theme: theme,
            ),
            _buildMenuItem(
              context,
              icon: Icons.show_chart,
              title: strings.statistics,
              route: AppConstants.statisticsRoute,
              isSelected: currentRoute == AppConstants.statisticsRoute,
              theme: theme,
            ),
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: strings.profile,
              route: AppConstants.profileRoute,
              isSelected: currentRoute == AppConstants.profileRoute,
              theme: theme,
            ),
            const Spacer(),
            _buildLogoutButton(context, strings, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings strings, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: theme.logoGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                strings.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            strings.version,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
        required bool isSelected,
        required AppTheme theme,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.primaryColor : theme.textSecondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.primaryColor : theme.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        if (route != currentRoute) {
          Navigator.of(context).pop(); // Fechar o drawer
          Navigator.of(context).pushReplacementNamed(route);
        } else {
          Navigator.of(context).pop(); // Apenas fechar o drawer
        }
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppStrings strings, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop(); // Fechar o drawer
          context.read<AuthBloc>().add(SignOutEvent());
        },
        icon: const Icon(Icons.logout),
        label: Text(strings.get('logout', defaultValue: 'Sair')),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.secondaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}