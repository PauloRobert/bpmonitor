import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/core/routes/app_router.dart';
import 'package:bp_monitor/core/theme/app_theme.dart';
import 'package:bp_monitor/core/di/injection_container.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_bloc.dart';

class BPMonitorApp extends StatelessWidget {
  const BPMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appTheme = sl<AppTheme>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>(),
        ),
        // Outros BLoCs serão adicionados aqui
      ],
      child: MaterialApp(
        title: 'BP Monitor',
        debugShowCheckedModeBanner: false,
        theme: appTheme.getThemeData(context),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        initialRoute: AppConstants.splashRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}