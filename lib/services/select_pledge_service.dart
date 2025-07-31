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
      // Development mode - skip payment and go directly to oath
      LogService.info("🔧 SKIP PAYMENT MODE - Going directly to oath");
      try {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OathScreen(
              userId: userId,
              challengeId: challengeId,
            ),
          ),
        );
        return true;
      } catch (e) {
        LogService.error("Error in skip payment mode: $e");
        return false;
      }
    } else {
      // Production mode - go through Stripe payment flow
      try {
        // Define your backend URL
        final String backendUrl =
            "https://us-central1-challenge-app-7.cloudfunctions.net/api/createCheckoutSession";

        // Convert amount to cents
        int amountInCents = (amount * 100).toInt();

        LogService.info("🎯 Creating checkout session:");
        LogService.info("🎯 User Id: $userId");
        LogService.info("🎯 Challenge Id: $challengeId");
        LogService.info("🎯 Amount: $amountInCents cents");

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

          LogService.info("🎯 Checkout session created successfully:");
          LogService.info("🎯 Session ID: $sessionId");
          LogService.info("🎯 Session URL: $sessionUrl");

          // Open Stripe Checkout in a new tab
          if (await canLaunch(sessionUrl)) {
            await launch(sessionUrl);
            LogService.info("🎯 Stripe checkout opened successfully");
          } else {
            throw 'Could not launch $sessionUrl';
          }

          // Navigate to PaymentStatusListener to monitor payment
          // Note: Server will now handle challenge joining automatically
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
          LogService.error(
              "Failed to create Checkout Session: ${response.statusCode} - ${response.body}");
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
    LogService.error("No authenticated user found");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to join the challenge.')),
    );
    return false;
  }
}
