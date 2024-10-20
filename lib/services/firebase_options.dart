import 'package:firebase_core/firebase_core.dart';
import '../services/log_service.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      LogService.info("Initializing Firebase with provided options");
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDDtJOweZ0r6f458ep8sER_pGl6q4EBajk",
          authDomain: "challenge-app-7.firebaseapp.com",
          databaseURL: "https://challenge-app-7-default-rtdb.firebaseio.com",
          projectId: "challenge-app-7",
          storageBucket: "challenge-app-7.appspot.com",
          messagingSenderId: "56606291217",
          appId: "1:56606291217:web:4b01f2e5b098788f8ec8b0",
          measurementId: "G-2DEKJF2E7Z",
        ),
      );
      LogService.info("Firebase initialized successfully");
    } catch (e, stackTrace) {
      LogService.error("Error initializing Firebase", e, stackTrace);
    }
  }
}
