import 'package:flutter/material.dart';
import 'services/firebase_options.dart';
import 'services/log_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LogService.info("Flutter bindings initialized");
  await FirebaseService.initializeFirebase();
  runApp(const ChallengeWebApp());
  LogService.info("ChallengeWebApp started");
}

class ChallengeWebApp extends StatelessWidget {
  const ChallengeWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.info("Building ChallengeWebApp");
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
