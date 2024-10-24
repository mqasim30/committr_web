// lib/screens/pledge_amount_selection_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/user_service.dart';
import '../widgets/loading_overlay.dart';

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

  /// Calculates the additional reward based on the pledge amount.
  double calculateAdditionalReward(double pledgeAmount) {
    return pledgeAmount - 5;
  }

  /// Handles the pledge selection and attempts to join the challenge.
  Future<void> selectPledgeAmount(double amount) async {
    setState(() {
      isLoading = true;
    });

    final currentUser = _userService.getCurrentUser();
    if (currentUser != null) {
      final userId = currentUser.uid;

      // Pass the BuildContext to joinChallenge
      bool joinResult = await _userService.joinChallenge(
          context, userId, widget.challenge, amount);

      setState(() {
        isLoading = false;
      });

      if (joinResult) {
        // Since navigation is handled in joinChallenge, no need to navigate back here.
        // Similarly, SnackBar is handled in UserService, so no need to show it here.
        // Optionally, you can show a success message or perform other actions if needed.
      } else {
        // If joinResult is false, it means either the user has already joined or an error occurred.
        // Error messages are handled within UserService, so no additional action is required here.
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
