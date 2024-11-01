// lib/services/select_pledge_service.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/user_service.dart';
import '../services/log_service.dart';
import '../screens/oath_screen.dart';

final UserService _userService = UserService();
const bool skipPayment = true; // Set to true to skip payment during testing

/// Handles the pledge selection and initiates the payment process.
Future<bool> selectPledgeAmount(
    BuildContext context, Challenge challenge, double amount) async {
  final currentUser = _userService.getCurrentUser();

  if (currentUser != null) {
    final String userId = currentUser.uid;
    final String challengeId = challenge.challengeId;

    if (skipPayment) {
      try {
        bool joinSuccess = await _userService.joinChallenge(
            context, userId, challenge, amount);

        if (joinSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OathScreen(
                userId: userId,
                challengeId: challengeId,
              ),
            ),
          );
        }
        return joinSuccess;
      } catch (e) {
        LogService.error("Error joining challenge: $e");
        return false;
      }
    } else {
      // Stripe payment code can go here if skipPayment is false
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to join the challenge.')),
    );
    return false;
  }
  return false;
}
