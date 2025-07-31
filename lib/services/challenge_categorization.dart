// lib/services/challenge_categorization.dart

import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import 'challenge_service.dart';
import 'user_service.dart';
import '../services/log_service.dart';

class ChallengeCategorization {
  final ChallengeService _challengeService;
  final UserService _userService;

  ChallengeCategorization(this._challengeService, this._userService);

  /// Returns a list of available challenges
  Future<List<Challenge>> getAvailableChallenges() async {
    List<Challenge> allChallenges =
        await _challengeService.fetchJoinableChallenges();
    Map<String, UserChallengeDetail> userChallenges =
        await _userService.getUserChallenges();

    List<Challenge> availableChallenges = allChallenges
        .where((challenge) =>
            !userChallenges.containsKey(challenge.challengeId) &&
            challenge.isJoinable)
        .toList();

    LogService.info(
        "Available challenges count: ${availableChallenges.length}");
    return availableChallenges;
  }

  /// Returns a list of active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    List<Challenge> allChallenges =
        await _challengeService.fetchActiveChallenges();
    Map<String, UserChallengeDetail> userChallenges =
        await _userService.getUserChallenges();

    List<Challenge> activeChallenges = allChallenges
        .where((challenge) =>
            userChallenges.containsKey(challenge.challengeId) &&
            (userChallenges[challenge.challengeId]!.userChallengeStatus ==
                    "In Progress" ||
                userChallenges[challenge.challengeId]!.userChallengeStatus ==
                    "Submission"))
        .toList();

    LogService.info("Active challenges count: ${activeChallenges.length}");
    return activeChallenges;
  }
}
