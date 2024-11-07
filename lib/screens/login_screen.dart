// lib/screens/login_screen.dart

import 'package:Committr/main.dart';
import 'package:Committr/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/google_sign_in_button.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    LogService.info("Login screen initialized");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _user = authService.getCurrentUser();
        LogService.info("Current user: $_user");
      });
    });
  }

  /// Handles the Google Sign-In process and navigates to the MainScreen upon success.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    LogService.info("Attempting Google Sign-In from Login Screen");
    final authService = Provider.of<AuthService>(context, listen: false);
    User? user = await authService.signInWithGoogle();
    setState(() {
      _isLoading = false;
      _user = user;
      LogService.info("User state updated: $_user");
    });
    if (user != null) {
      LogService.info("User signed in: $user");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully')),
      );
      // Navigate to MainScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreenWithListener()),
      );
    } else {
      LogService.warning("Google Sign-In failed or was canceled");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed or was canceled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double aspectRatio = screenWidth / screenHeight;

    double titleFontSize = (screenHeight * 0.05).roundToDouble();
    double stepGranularity = 1.0;
    bool isNarrowPortrait = aspectRatio < 0.6;

    Alignment textAlignment;
    EdgeInsetsGeometry titlePadding;

    if (isNarrowPortrait) {
      textAlignment = Alignment.centerLeft;
      titlePadding = EdgeInsets.symmetric(horizontal: screenWidth * 0.05);
    } else {
      textAlignment = Alignment.center;
      titlePadding = EdgeInsets.only(
        left: 0,
        right: screenWidth * 0.1,
      );
    }

    double maxTitleWidth = screenWidth * 0.8;
    double maxAllowedTitleWidth = 600.0;
    if (maxTitleWidth > maxAllowedTitleWidth) {
      maxTitleWidth = maxAllowedTitleWidth;
    }

    bool isPortrait = aspectRatio < 1;
    double buttonWidth;
    if (isPortrait) {
      if (isNarrowPortrait) {
        buttonWidth = screenWidth * 0.9;
      } else {
        buttonWidth = screenWidth * 0.6;
      }
    } else {
      buttonWidth = screenWidth * 0.3;
      double minButtonWidth = 300;
      if (buttonWidth < minButtonWidth) {
        buttonWidth = minButtonWidth;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color.fromARGB(255, 159, 232, 112),
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: textAlignment,
                    child: Padding(
                      padding: titlePadding,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxTitleWidth),
                        child: AutoSizeText(
                          'Track.\nCommit.\nAchieve.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                            height: 1.1,
                            color: const Color.fromARGB(255, 8, 52, 0),
                          ),
                          maxLines: 3,
                          minFontSize: 10,
                          stepGranularity: stepGranularity,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: buttonWidth,
                      child: kIsWeb
                          ? ElevatedButton(
                              onPressed: _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      screenHeight * 0.07 * 0.5),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.07 * 0.2,
                                ),
                                minimumSize: Size(
                                  double.infinity,
                                  screenHeight * 0.07,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Image.asset(
                                      'assets/images/google_icon.png',
                                      height: screenHeight * 0.07 * 0.5,
                                      width: screenHeight * 0.07 * 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: screenHeight * 0.08 * 0.35,
                                          color: const Color.fromARGB(
                                              255, 50, 50, 50),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: LoadingOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}
