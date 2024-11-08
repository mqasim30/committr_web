// lib/widgets/weight_challenge_progress_widget.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../utils/challenge_helper.dart';

class WeightChallengeProgressWidget extends StatelessWidget {
  final Challenge challenge;
  final UserChallengeDetail userChallengeDetail;
  final DateTime currentDate;

  const WeightChallengeProgressWidget({
    super.key,
    required this.challenge,
    required this.userChallengeDetail,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieve weight data
    final startingWeight = userChallengeDetail.challengeData['startingWeight'];
    final currentWeight = userChallengeDetail.challengeData['currentWeight'];
    final weightUnit = userChallengeDetail.challengeData['weightUnit'] ?? 'kg';
    final challengeType =
        ChallengeHelper.getChallengeType(challenge.challengeTitle);

    // Check and parse weight data
    double? startingWeightValue = _parseWeight(startingWeight);
    double? currentWeightValue = _parseWeight(currentWeight);

    final endDate =
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeEndTimestamp);
    final daysLeft = ChallengeHelper.calculateDaysLeft(endDate, currentDate);
    final goalWeight = ChallengeHelper.calculateGoalWeight(
        challengeType, startingWeightValue!);

    // Adjust weight units if needed
    final adjustedGoalWeight =
        weightUnit == 'lb' ? goalWeight! * 2.20462 : goalWeight;

    return Column(
      children: [
        // Weight Information using cards
        _buildWeightInfo(
          currentWeight: currentWeightValue,
          startingWeight: startingWeightValue,
          goalWeight: adjustedGoalWeight,
          weightUnit: weightUnit,
          daysLeft: daysLeft,
          challengeType: challengeType,
        ),
      ],
    );
  }

  // Helper function to parse weights
  double? _parseWeight(dynamic weight) {
    if (weight is double) return weight;
    if (weight is int) return weight.toDouble();
    return double.tryParse(weight.toString());
  }

  // Weight Info Section Builder with Cards
  Widget _buildWeightInfo({
    required double? currentWeight,
    required double? startingWeight,
    required double? goalWeight,
    required String weightUnit,
    required int daysLeft,
    required ChallengeType challengeType,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChallengeInfoCard(
              title: "Current Weight",
              value: currentWeight != null
                  ? "${currentWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
            const SizedBox(width: 8),
            _ChallengeInfoCard(
              title: "Starting Weight",
              value: startingWeight != null
                  ? "${startingWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChallengeInfoCard(
              title: "Goal Weight",
              value: goalWeight != null
                  ? "${goalWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
            const SizedBox(width: 8),
            _ChallengeInfoCard(
              title: "Days Left",
              value: "$daysLeft",
            ),
          ],
        ),
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
    return Expanded(
      child: Card(
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
      ),
    );
  }
}
