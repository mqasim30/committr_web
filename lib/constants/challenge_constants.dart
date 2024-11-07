// lib/constants/challenge_constants.dart

class ChallengeConstants {
  static const String LOSE_4_PERCENT = "Lose 4% Weight in 4 Weeks";
  static const String LOSE_10_PERCENT = "Lose 10% Weight in 3 Months";
  static const String MAINTAIN_WEIGHT = "Maintain Weight for 6 Months";
  static const String WAKE_UP_EARLY = "Wake Up Early";
  static const String REDUCE_SCREEN_TIME = "Reduce Screen Time";

  static String getDetailedDescription(String title) {
    switch (title) {
      case LOSE_4_PERCENT:
        return "You need to lose 4% of your weight within 4 weeks.";
      case LOSE_10_PERCENT:
        return "You need to lose 10% of your weight within 3 months.";
      case MAINTAIN_WEIGHT:
        return "You need to maintain your current weight for 6 months.";
      case WAKE_UP_EARLY:
        return "Aim to wake up early consistently for the duration of the challenge.";
      case REDUCE_SCREEN_TIME:
        return "Aim to reduce your daily screen time by half.";
      default:
        return "Commit to the challenge to achieve your goal.";
    }
  }
}
