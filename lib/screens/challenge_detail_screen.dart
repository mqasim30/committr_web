// lib/screens/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../widgets/loading_overlay.dart';
import 'pledge_amount_selection_screen.dart';
import 'oath_screen.dart';
import '../providers/challenge_provider.dart';
import '../services/auth_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  _ChallengeDetailScreenState createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize loading state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  /// Navigates to the Pledge Amount Selection Screen.
  void navigateToPledgeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PledgeAmountSelectionScreen(challenge: widget.challenge),
      ),
    ).then((_) {
      // No need to refresh; ChallengeProvider handles real-time updates
    });
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final updatedChallenge = challengeProvider.activeChallenges.firstWhere(
        (c) => c.challengeId == widget.challenge.challengeId,
        orElse: () => widget.challenge);

    // Retrieve UserChallengeDetail from the provider
    final userChallengeDetail =
        challengeProvider.userChallenges[widget.challenge.challengeId];

    return Scaffold(
      appBar: AppBar(
        title: Text(updatedChallenge.challengeTitle),
      ),
      body: Stack(
        children: [
          if (isLoading)
            const LoadingOverlay(), // Display loading overlay while fetching data
          if (!isLoading)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Challenge Description
                  Text(
                    updatedChallenge.challengeDescription,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Challenge Duration
                  Text(
                    'Duration: ${updatedChallenge.challengeDurationDays} days',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Challenge Category
                  Text(
                    'Category: ${updatedChallenge.challengeCategory}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Pot Size
                  Text(
                    'Pot Size: \$${updatedChallenge.challengePotSize}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Number of Participants
                  Text(
                    'Participants: ${updatedChallenge.challengeParticipantsId.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Challenge Rules
                  const Text(
                    'Rules:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ...updatedChallenge.rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        rule,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Challenge Oath (Removed)
                  // If needed, add a description or instructions here.

                  const SizedBox(height: 20),

                  // Join Challenge Button or User-specific Details
                  if (userChallengeDetail == null)
                    ElevatedButton(
                      onPressed: navigateToPledgeSelection,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        'Join Challenge',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You have already joined this challenge.',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pledge Amount: \$${userChallengeDetail.userChallengePledgeAmount}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Status: ${userChallengeDetail.userChallengeStatus}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          if (!userChallengeDetail.isOathTaken)
                            ElevatedButton(
                              onPressed: () {
                                final authService = Provider.of<AuthService>(
                                    context,
                                    listen: false);
                                final currentUser = authService.currentUser;
                                if (currentUser != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OathScreen(
                                        userId: currentUser.uid,
                                        challengeId:
                                            updatedChallenge.challengeId,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('User not authenticated.')),
                                  );
                                }
                              },
                              child: const Text('Take Oath'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
