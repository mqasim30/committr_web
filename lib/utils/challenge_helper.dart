// lib/utils/challenge_helper.dart

import '../constants/challenge_constants.dart';

enum ChallengeType {
  Lose4Percent,
  Lose10Percent,
  MaintainWeight,
  WakeUpEarly,
  ReduceScreenTime,
  Unknown
}

class ChallengeHelper {
  /// Determines the challenge type based on the challenge title.
  static ChallengeType getChallengeType(String challengeTitle) {
    if (challengeTitle == ChallengeConstants.LOSE_4_PERCENT) {
      return ChallengeType.Lose4Percent;
    } else if (challengeTitle == ChallengeConstants.LOSE_10_PERCENT) {
      return ChallengeType.Lose10Percent;
    } else if (challengeTitle == ChallengeConstants.MAINTAIN_WEIGHT) {
      return ChallengeType.MaintainWeight;
    } else if (challengeTitle == ChallengeConstants.WAKE_UP_EARLY) {
      return ChallengeType.WakeUpEarly;
    } else if (challengeTitle == ChallengeConstants.REDUCE_SCREEN_TIME) {
      return ChallengeType.ReduceScreenTime;
    } else {
      return ChallengeType.Unknown;
    }
  }

  /// Calculates the goal based on the challenge type.
  /// Returns a double for weight-related challenges and null otherwise.
  static double? calculateGoalWeight(
      ChallengeType type, double startingWeight) {
    switch (type) {
      case ChallengeType.Lose4Percent:
        return startingWeight * 0.96; // Lose 4%
      case ChallengeType.Lose10Percent:
        return startingWeight * 0.90; // Lose 10%
      case ChallengeType.MaintainWeight:
        // For maintain weight, define a range (+/-2%)
        // Here, we'll return the starting weight as the goal.
        return startingWeight;
      // For non-weight challenges, return null
      case ChallengeType.WakeUpEarly:
      case ChallengeType.ReduceScreenTime:
        return null;
      case ChallengeType.Unknown:
      default:
        return null;
    }
  }

  /// Calculates the progress percentage based on challenge start and end dates.
  /// Returns a value between 0.0 and 1.0.
  static double calculateProgress(
      DateTime startDate, DateTime endDate, DateTime currentDate) {
    if (currentDate.isBefore(startDate)) {
      return 0.0;
    } else if (currentDate.isAfter(endDate)) {
      return 1.0;
    }
    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsed = currentDate.difference(startDate).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  /// Calculates the days left in the challenge.
  static int calculateDaysLeft(DateTime endDate, DateTime currentDate) {
    final daysLeft = endDate.difference(currentDate).inDays;
    return daysLeft > 0 ? daysLeft : 0;
  }

  /// Calculates the goal weight range for Maintain Weight challenge.
  static Map<String, double>? calculateMaintainWeightRange(
      double startingWeight) {
    return {
      'upper': startingWeight * 1.02, // +2%
      'lower': startingWeight * 0.98, // -2%
    };
  }
}
