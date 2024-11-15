// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/log_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/ip_service.dart';
import 'services/geolocation_service.dart';
import 'services/challenge_service.dart';
import 'services/user_service.dart';
import 'providers/challenge_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/loading_overlay.dart';
import 'services/firebase_service.dart';
import 'services/firebase_analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  LogService.info("Environment variables loaded");

  try {
    await FirebaseService.initializeFirebase();

    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    await analyticsService.initialize();

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
          Provider<AuthService>(
            create: (context) => AuthService(
              databaseService:
                  Provider.of<DatabaseService>(context, listen: false),
              ipService: Provider.of<IPService>(context, listen: false),
              geolocationService:
                  Provider.of<GeolocationService>(context, listen: false),
            ),
          ),
          Provider<ChallengeService>(
            create: (_) => ChallengeService(),
          ),
          Provider<UserService>(
            create: (_) => UserService(),
          ),
          ChangeNotifierProvider<ChallengeProvider>(
            create: (context) => ChallengeProvider(
              Provider.of<ChallengeService>(context, listen: false),
              Provider.of<UserService>(context, listen: false),
            ),
          ),
          Provider<FirebaseAnalyticsService>(
            create: (_) => analyticsService,
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

    final FirebaseAnalyticsService analyticsService =
        Provider.of<FirebaseAnalyticsService>(context, listen: false);

    return MaterialApp(
      title: 'Committr',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreenWithListener(),
        // Add other routes as needed
      },
      navigatorObservers: [
        analyticsService.getObserver(),
      ],
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
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      LogService.info("User is already signed in: ${user.uid}");
      bool updateResult = await _authService.updateUserProfileForUser(user.uid);
      if (updateResult) {
        LogService.info("User profile updated successfully for ${user.uid}");
        // Fetch challenges after user profile is updated
        await Provider.of<ChallengeProvider>(context, listen: false)
            .initialize();
        // Navigate to MainScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreenWithListener()),
            );
          }
        });
      } else {
        LogService.error("Failed to update user profile for ${user.uid}");
        // Navigate to LoginScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      }
    } else {
      LogService.info("No user is signed in. Navigating to LoginScreen.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    }

    // Removed setState() to prevent the error
  }

  @override
  Widget build(BuildContext context) {
    // Use your LoadingOverlay widget
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading) const LoadingOverlay(), // Using your LoadingOverlay
        ],
      ),
    );
  }
}

class MainScreenWithListener extends StatelessWidget {
  const MainScreenWithListener({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const MainScreen(),
        ],
      ),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.error(
        "FirebaseErrorApp displayed due to initialization failure.");
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
