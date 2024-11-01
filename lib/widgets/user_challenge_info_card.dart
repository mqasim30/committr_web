// lib/widgets/user_challenge_info_card.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/oath_screen.dart';

class UserChallengeInfoCard extends StatelessWidget {
  final userChallengeDetail;
  final String challengeId;
  final AuthService authService;

  const UserChallengeInfoCard({
    super.key,
    required this.userChallengeDetail,
    required this.challengeId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have already joined this challenge.',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
              'Pledge Amount: \$${userChallengeDetail.userChallengePledgeAmount}',
              style: const TextStyle(fontSize: 16)),
          Text('Status: ${userChallengeDetail.userChallengeStatus}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          if (!userChallengeDetail.isOathTaken)
            ElevatedButton(
              onPressed: () {
                final currentUser = authService.currentUser;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OathScreen(
                        userId: currentUser.uid,
                        challengeId: challengeId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not authenticated.')),
                  );
                }
              },
              child: const Text('Take Oath'),
            ),
        ],
      ),
    );
  }
}
