// lib/services/select_pledge_service.dart - SECURE VERSION

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/user_service.dart';
import '../services/log_service.dart';
import '../screens/payment_status_listener.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

final UserService _userService = UserService();

Future<bool> selectPledgeAmount(
    BuildContext context, Challenge challenge, double amount) async {
  final currentUser = _userService.getCurrentUser();

  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to join the challenge.')),
    );
    return false;
  }

  final String userId = currentUser.uid;
  final String challengeId = challenge.challengeId;

  // SECURITY: Always require payment - NO BYPASS ALLOWED
  try {
    // Get the user's authentication token
    String? idToken = await currentUser.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token');
    }

    // Validate inputs
    if (amount < 35 || amount > 200) {
      throw Exception('Invalid amount. Must be between \$35 and \$200.');
    }

    if (challengeId.isEmpty) {
      throw Exception('Invalid challenge ID.');
    }

    // Define your secure backend URL
    final String backendUrl =
        "https://us-central1-challenge-app-7.cloudfunctions.net/api/createCheckoutSession";

    // Convert amount to cents (but send as dollars to server for validation)
    int amountInCents = (amount * 100).toInt();

    LogService.info(
        "User Id: $userId, Challenge Id: $challengeId, Amount: \$${amount}");

    // Create Checkout Session with authentication
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken', // Include auth token
      },
      body: json.encode({
        'amount': amountInCents,
        'challengeId': challengeId,
        // userId is extracted from the auth token on server side
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String sessionId = data['sessionId'];
      String sessionUrl = data['sessionUrl'];

      // Validate the response
      if (sessionId.isEmpty || sessionUrl.isEmpty) {
        throw Exception('Invalid response from payment service');
      }

      // Open Stripe Checkout in a new tab
      final Uri sessionUri = Uri.parse(sessionUrl);
      if (await canLaunchUrl(sessionUri)) {
        await launchUrl(sessionUri);
      } else {
        throw Exception('Could not launch payment page');
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
    } else if (response.statusCode == 400) {
      // Handle validation errors
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Invalid request');
    } else if (response.statusCode == 401) {
      // Handle authentication errors
      throw Exception('Please sign in again to continue');
    } else {
      // Handle server errors
      throw Exception(
          'Payment service temporarily unavailable. Please try again.');
    }
  } catch (e) {
    LogService.error("Error initiating payment: $e");

    String userMessage;
    if (e.toString().contains('authentication') ||
        e.toString().contains('token')) {
      userMessage = 'Please sign in again to continue.';
    } else if (e.toString().contains('Invalid amount')) {
      userMessage = 'Please select a valid pledge amount.';
    } else if (e.toString().contains('already joined')) {
      userMessage = 'You have already joined this challenge.';
    } else if (e.toString().contains('not joinable')) {
      userMessage = 'This challenge is no longer available.';
    } else {
      userMessage = 'Payment failed. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessage)),
    );
    return false;
  }
}
