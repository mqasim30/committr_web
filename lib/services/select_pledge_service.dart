// lib/services/select_pledge_service.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/user_service.dart';
import '../services/log_service.dart';
import '../screens/oath_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../screens/payment_status_listener.dart';

final UserService _userService = UserService();
const bool skipPayment = false; // Set to false to enable payment

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
      // Stripe payment flow for web-only
      try {
        // Define your backend URL
        final String backendUrl =
            "https://us-central1-challenge-app-7.cloudfunctions.net/api/createCheckoutSession";

        // Convert amount to cents
        int amountInCents = (amount * 100).toInt();
        LogService.info(
            "User Id: $userId , Challenge Id: $challengeId , Amount: $amountInCents");
        // Create Checkout Session
        final response = await http.post(
          Uri.parse(backendUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'amount': amountInCents,
            'userId': userId,
            'challengeId': challengeId,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String sessionId = data['sessionId'];
          String sessionUrl = data['sessionUrl'];

          // Open Stripe Checkout in a new tab
          if (await canLaunch(sessionUrl)) {
            await launch(sessionUrl);
          } else {
            throw 'Could not launch $sessionUrl';
          }

          // Navigate to PaymentStatusListener to monitor payment
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentStatusListener(
                sessionId: sessionId,
                userId: userId,
                challengeId: challengeId,
                pledgeAmount: amount,
              ),
            ),
          );

          return true;
        } else {
          // Handle error response
          throw 'Failed to create Checkout Session: ${response.body}';
        }
      } catch (e) {
        LogService.error("Error initiating payment: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        return false;
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to join the challenge.')),
    );
    return false;
  }
}
