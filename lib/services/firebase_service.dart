// firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import '../services/log_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// FirebaseService handles the initialization of Firebase with environment configurations.
class FirebaseService {
  /// Initializes Firebase using environment variables.
  static Future<void> initializeFirebase() async {
    try {
      LogService.info("Initializing Firebase with provided options");
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY']!,
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
          databaseURL: dotenv.env['FIREBASE_DATABASE_URL']!,
          projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
          appId: dotenv.env['FIREBASE_APP_ID']!,
          measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']!,
        ),
      );
      LogService.info("Firebase initialized successfully");
    } catch (e, stackTrace) {
      LogService.error("Error initializing Firebase", e, stackTrace);
      rethrow; // To allow handling in main.dart
    }
  }
}
