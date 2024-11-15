// lib/services/firebase_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'log_service.dart';
import '../services/user_service.dart';

class FirebaseAnalyticsService {
  // Singleton pattern
  FirebaseAnalyticsService._privateConstructor();
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._privateConstructor();
  factory FirebaseAnalyticsService() => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalytics get analytics => _analytics;
  final UserService _userService = UserService();

  Future<void> initialize() async {
    try {
      final currentUser = _userService.getCurrentUser();
      await _analytics.setUserId(id: currentUser?.uid);
      LogService.info("Firebase Analytics initialized.");
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to initialize Firebase Analytics", e, stackTrace);
    }
  }

  String _formatEventName(
      {required String screenName, required String action}) {
    return '${action.toLowerCase()}_${screenName.toLowerCase()}';
  }

  Future<void> logCustomEvent({
    required String screenName,
    required String action,
    Map<String, Object>? parameters,
  }) async {
    final eventName = _formatEventName(screenName: screenName, action: action);

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      LogService.debug(
          "Logged custom event: $eventName with parameters: $parameters");
    } catch (e, stackTrace) {
      LogService.error("Failed to log custom event: $eventName", e, stackTrace);
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      LogService.debug("Logged screen view: $screenName");
    } catch (e, stackTrace) {
      LogService.error("Failed to log screen view: $screenName", e, stackTrace);
    }
  }

  FirebaseAnalyticsObserver getObserver() {
    LogService.debug("FirebaseAnalyticsObserver created.");
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}
