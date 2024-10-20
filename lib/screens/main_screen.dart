// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle sign-out
              // You might need to implement sign-out logic in AuthService
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Available Challenges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            challengeProvider.availableChallenges.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challengeProvider.availableChallenges.length,
                    itemBuilder: (context, index) {
                      Challenge challenge =
                          challengeProvider.availableChallenges[index];
                      return ListTile(
                        title: Text(challenge.challengeTitle),
                        subtitle: Text(challenge.challengeDescription),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Handle joining the challenge
                            // Implement logic to update UserChallengeDetail in Firebase
                          },
                          child: const Text('Join'),
                        ),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No available challenges at the moment.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(height: 40),
            const Text(
              'Active Challenges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            challengeProvider.activeChallenges.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challengeProvider.activeChallenges.length,
                    itemBuilder: (context, index) {
                      Challenge challenge =
                          challengeProvider.activeChallenges[index];
                      return ListTile(
                        title: Text(challenge.challengeTitle),
                        subtitle: Text('Status: In Progress'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Handle viewing challenge details
                            // Implement navigation to a detailed challenge view
                          },
                          child: const Text('View'),
                        ),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No active challenges at the moment.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
