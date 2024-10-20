import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/google_sign_in_button.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    LogService.info("Login screen initialized");
    _user = _authService.getCurrentUser();
    LogService.info("Current user: $_user");
  }

  Future<void> _signInWithGoogle() async {
    LogService.info("Attempting Google Sign-In from Login Screen");
    User? user = await _authService.signInWithGoogle();
    LogService.info("User signed in: $user");
    setState(() {
      _user = user;
      LogService.info("User state updated: $_user");
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double aspectRatio = screenWidth / screenHeight;

    double titleFontSize = (screenHeight * 0.07).roundToDouble();
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
      body: Container(
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
                        fontWeight: FontWeight.w600,
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
                  child: GoogleSignInButton(
                    onPressed: _signInWithGoogle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
