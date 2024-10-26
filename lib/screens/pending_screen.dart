// lib/screens/pending_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';

class PendingScreen extends StatelessWidget {
  final Challenge challenge;

  const PendingScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Pending'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Your submission for "${challenge.challengeTitle}" is under review.',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'We are currently reviewing your submission. You will be notified once the review is complete.',
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
