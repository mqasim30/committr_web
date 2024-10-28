// lib/screens/pledge_amount_selection_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/user_service.dart';
import '../widgets/loading_overlay.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'payment_status_listener.dart';
import '../services/log_service.dart';
import 'oath_screen.dart'; // Import OathScreen to navigate directly

class PledgeAmountSelectionScreen extends StatefulWidget {
  final Challenge challenge;

  const PledgeAmountSelectionScreen({
    super.key,
    required this.challenge,
  });

  @override
  _PledgeAmountSelectionScreenState createState() =>
      _PledgeAmountSelectionScreenState();
}

class _PledgeAmountSelectionScreenState
    extends State<PledgeAmountSelectionScreen> {
  bool isLoading = false;
  final UserService _userService = UserService();

  // Define the available pledge amounts
  final List<double> pledgeAmounts = [35.0, 55.0, 75.0, 95.0];

  // Add this flag to skip payment during testing
  static const bool skipPayment =
      true; // Set to true to skip payment during testing

  /// Calculates the additional reward based on the pledge amount.
  double calculateAdditionalReward(double pledgeAmount) {
    return pledgeAmount - 5;
  }

  /// Handles the pledge selection and initiates the payment process.
  Future<void> selectPledgeAmount(double amount) async {
    setState(() {
      isLoading = true;
    });

    final currentUser = _userService.getCurrentUser();
    if (currentUser != null) {
      final String userId = currentUser.uid;
      final String challengeId = widget.challenge.challengeId;

      if (skipPayment) {
        // Simulate successful payment
        try {
          // Call joinChallenge with pledgeAmount
          bool joinSuccess = await _userService.joinChallenge(
              context, userId, widget.challenge, amount);

          if (joinSuccess) {
            // Navigate to OathScreen upon successful join
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OathScreen(
                  userId: userId,
                  challengeId: challengeId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to join challenge.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error joining challenge: $e')),
          );
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // Existing Stripe payment code
        try {
          final int amountInCents = (amount * 100).toInt();

          // Create Checkout Session
          final response = await http.post(
            Uri.parse(
                'https://createcheckoutsession-zkxlm7bvjq-uc.a.run.app/createCheckoutSession'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amountInCents,
              'userId': userId, // Pass the user ID
              'challengeId': challengeId, // Pass the challenge ID
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final sessionUrl = data['sessionUrl'];
            final sessionId = data['sessionId'];

            if (sessionUrl == null ||
                sessionUrl.isEmpty ||
                sessionId == null ||
                sessionId.isEmpty) {
              throw Exception('Invalid session URL or ID received.');
            }

            LogService.info('Received sessionUrl: $sessionUrl');

            // Launch Stripe Checkout
            final Uri checkoutUri = Uri.parse(sessionUrl);
            if (await canLaunchUrl(checkoutUri)) {
              await launchUrl(
                checkoutUri,
                mode: LaunchMode
                    .externalApplication, // Ensures it opens in a new tab
              );

              // Navigate to the PaymentStatusListener
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentStatusListener(
                    pledgeAmount: amount,
                    sessionId: sessionId,
                    userId: userId,
                    challengeId: challengeId,
                  ),
                ),
              );

              setState(() {
                isLoading = false;
              });
            } else {
              throw Exception('Could not launch $sessionUrl');
            }
          } else {
            // Attempt to parse the error message from the response
            String errorMsg = 'Failed to create checkout session.';
            try {
              final errorData = jsonDecode(response.body);
              if (errorData['error']) {
                errorMsg = errorData['error']['message'] ?? errorMsg;
              }
            } catch (_) {}
            throw Exception(errorMsg);
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          // Handle error during payment
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${e.toString()}')),
          );
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to join the challenge.')),
      );
      Navigator.pop(context); // Navigate back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pledge Amount'),
      ),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.challenge.challengeTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.challenge.challengeDescription,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Choose your pledge amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // Pledge Amount Buttons
                Column(
                  children: pledgeAmounts.map((amount) {
                    double additionalReward = calculateAdditionalReward(amount);
                    double totalReward = amount + additionalReward;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () => selectPledgeAmount(amount),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 12.0),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${amount.toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'If 50% of the members complete this challenge you will get additional reward. \$${amount.toInt()} + \$${additionalReward.toInt()} (\$${totalReward.toInt()} in total)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Loading Overlay
          if (isLoading)
            const LoadingOverlay(), // Display loading overlay during join operation
        ],
      ),
    );
  }
}
