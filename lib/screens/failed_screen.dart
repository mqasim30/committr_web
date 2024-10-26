// lib/screens/failed_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';

class FailedScreen extends StatelessWidget {
  final Challenge challenge;

  const FailedScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Not Completed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'You did not meet the requirements for "${challenge.challengeTitle}".',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Don\'t be discouraged! Reflect on what you can improve and consider joining another challenge.',
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
