import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  final AppLogger _logger;

  AnalyticsService({
    required FirebaseAnalytics analytics,
    required FirebaseCrashlytics crashlytics,
    required AppLogger logger,
  }) : _analytics = analytics,
        _crashlytics = crashlytics,
        _logger = logger;

  Future<void> init() async {
    try {
      // Inicializar Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Configurar o observer para o FlutterError
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterError(details);
        // Ainda mostrar o erro no console
        FlutterError.dumpErrorToConsole(details);
      };

      _logger.i('Analytics e Crashlytics inicializados');
    } catch (e) {
      _logger.e('Erro ao inicializar Analytics/Crashlytics', e);
    }
  }

  // Log de eventos no Analytics
  Future<void> logEvent({required String name, Map<String, Object?>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      _logger.d('Evento registrado: $name');
    } catch (e) {
      _logger.e('Erro ao registrar evento: $name', e);
    }
  }

  // Registrar erro no Crashlytics
  Future<void> logError(dynamic error, StackTrace stackTrace, {String? reason}) async {
    try {
      await _crashlytics.recordError(error, stackTrace, reason: reason);
      _logger.e('Erro enviado para Crashlytics: $reason', error, stackTrace);
    } catch (e) {
      _logger.e('Erro ao enviar erro para Crashlytics', e);
    }
  }

  // Definir usuário atual para Crashlytics e Analytics
  Future<void> setUser(String? userId) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
        _logger.d('ID do usuário definido: $userId');
      } else {
        await _analytics.setUserId();
        await _crashlytics.setUserIdentifier('');
        _logger.d('ID do usuário removido');
      }
    } catch (e) {
      _logger.e('Erro ao definir ID do usuário', e);
    }
  }

  // Definir propriedade do usuário
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logger.d('Propriedade do usuário definida: $name = $value');
    } catch (e) {
      _logger.e('Erro ao definir propriedade do usuário', e);
    }
  }

  // Registrar tela atual
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _logger.d('Visualização de tela registrada: $screenName');
    } catch (e) {
      _logger.e('Erro ao registrar visualização de tela', e);
    }
  }

  // Registrar evento de medição
  Future<void> logMeasurement({
    required int systolic,
    required int diastolic,
    required int heartRate,
    required String category,
  }) async {
    await logEvent(
      name: 'measurement_added',
      parameters: {
        'systolic': systolic,
        'diastolic': diastolic,
        'heart_rate': heartRate,
        'category': category,
      },
    );
  }
}