// lib/screens/completed_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';

class CompletedScreen extends StatelessWidget {
  final Challenge challenge;

  const CompletedScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Completed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Congratulations! You have successfully completed "${challenge.challengeTitle}".',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Thank you for participating in the challenge. Keep up the great work!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Optionally, provide further instructions or options
            ElevatedButton(
              onPressed: () {
                // Navigate back to MainScreen or another appropriate action
                Navigator.pop(context);
              },
              child: const Text('Return to Main Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
