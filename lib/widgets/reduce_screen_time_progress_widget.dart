import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../utils/challenge_helper.dart';

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
    final endDate =
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeEndTimestamp);
    final daysLeft = ChallengeHelper.calculateDaysLeft(endDate, currentDate);

    return Column(
      children: [
        // Centered Days Left Card with fixed width
        Center(
          child: SizedBox(
            width: 200, // Set a fixed width to match other progress widgets
            child: _ChallengeInfoCard(
              title: "Days Left",
              value: "$daysLeft",
            ),
          ),
        ),
        // Additional UI components can be added here if needed
      ],
    );
  }
}

class _ChallengeInfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _ChallengeInfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 24,
                color: AppColors.mainFGColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.mainFGColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
