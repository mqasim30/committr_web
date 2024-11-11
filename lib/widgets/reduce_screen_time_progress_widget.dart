import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';

class ReduceScreenTimeProgressWidget extends StatelessWidget {
  final Challenge challenge;
  final UserChallengeDetail userChallengeDetail;
  final DateTime currentDate;

  const ReduceScreenTimeProgressWidget({
    super.key,
    required this.challenge,
    required this.userChallengeDetail,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieve daily usage and calculate goal
    final dailyUsage = double.tryParse(
            userChallengeDetail.challengeData['dailyUsage'] ?? '0') ??
        0.0;
    final goalUsage = dailyUsage / 2;

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 400,
            child: _GoalInfoCard(
              title: "Screen Time Goal",
              startingUsage: "${dailyUsage.toStringAsFixed(1)} hours/day",
              goalUsage: "${goalUsage.toStringAsFixed(1)} hours/day",
            ),
          ),
        ),
        // Additional UI components can be added here if needed
      ],
    );
  }
}

class _GoalInfoCard extends StatelessWidget {
  final String title;
  final String startingUsage;
  final String goalUsage;

  const _GoalInfoCard({
    required this.title,
    required this.startingUsage,
    required this.goalUsage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400, // Ensure the card itself has a fixed width
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.mainFGColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Starting Usage:",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  startingUsage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Goal Usage:",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  goalUsage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
