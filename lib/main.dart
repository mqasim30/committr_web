// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/log_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/ip_service.dart';
import 'services/geolocation_service.dart';
import 'services/challenge_service.dart';
import 'services/user_service.dart';
import 'services/challenge_categorization.dart';
import 'providers/challenge_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/loading_overlay.dart';
import 'widgets/challenge_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  LogService.info("Environment variables loaded");

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      ),
    );

    LogService.info("Firebase initialized successfully");
    runApp(
      MultiProvider(
        providers: [
          Provider<DatabaseService>(
            create: (_) => DatabaseService(),
          ),
          Provider<IPService>(
            create: (_) => IPService(),
          ),
          Provider<GeolocationService>(
            create: (_) => GeolocationService(),
          ),
          ProxyProvider3<DatabaseService, IPService, GeolocationService,
              AuthService>(
            update: (_, databaseService, ipService, geolocationService, __) =>
                AuthService(
              databaseService: databaseService,
              ipService: ipService,
              geolocationService: geolocationService,
            ),
          ),
          Provider<ChallengeService>(
            create: (_) => ChallengeService(),
          ),
          Provider<UserService>(
            create: (_) => UserService(),
          ),
          Provider<ChallengeCategorization>(
            create: (context) => ChallengeCategorization(
              Provider.of<ChallengeService>(context, listen: false),
              Provider.of<UserService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider<ChallengeProvider>(
            create: (context) => ChallengeProvider(
              Provider.of<ChallengeCategorization>(context, listen: false),
            ),
          ),
        ],
        child: const ChallengeWebApp(),
      ),
    );
    LogService.info("ChallengeWebApp started");
  } catch (e, stackTrace) {
    LogService.error("Failed to initialize Firebase", e, stackTrace);
    runApp(const FirebaseErrorApp());
  }
}

class ChallengeWebApp extends StatelessWidget {
  const ChallengeWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.info("Building ChallengeWebApp");

    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light, // Force light theme to avoid dark backgrounds
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthService _authService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      LogService.info("User is already signed in: ${user.uid}");
      bool updateResult = await _authService.updateUserProfileForUser(user.uid);
      if (updateResult) {
        LogService.info("User profile updated successfully for ${user.uid}");
        // Navigate to MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        LogService.error("Failed to update user profile for ${user.uid}");
        // Optionally, show an error or navigate to LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      LogService.info("No user is signed in. Navigating to LoginScreen.");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while checking auth state
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const LoadingOverlay(), // Use the centralized LoadingOverlay
          if (!_isLoading)
            const ChallengeListener(), // Start listening after loading
        ],
      ),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize Firebase. Please try again later.',
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
