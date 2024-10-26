// lib/screens/missed_submission_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';

class MissedSubmissionScreen extends StatelessWidget {
  final Challenge challenge;

  const MissedSubmissionScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Missed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'You have missed the submission deadline for "${challenge.challengeTitle}".',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Unfortunately, since you did not submit your final weight and image before the deadline, you are not eligible for any rewards from this challenge.',
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
