// lib/models/user_challenge_detail.dart

class UserChallengeDetail {
  final String userChallengeId;
  final double userChallengePledgeAmount;
  final String userChallengeStatus;
  final bool isOathTaken;
  final Map<String, dynamic> challengeData;

  UserChallengeDetail({
    required this.userChallengeId,
    required this.userChallengePledgeAmount,
    required this.userChallengeStatus,
    required this.isOathTaken,
    required this.challengeData,
  });

  /// Creates a [UserChallengeDetail] instance from a Map.
  factory UserChallengeDetail.fromMap(Map<dynamic, dynamic> map) {
    return UserChallengeDetail(
      userChallengeId: map['UserChallengeId'] ?? '',
      userChallengePledgeAmount:
          (map['UserChallengePledgeAmount'] ?? 0).toDouble(),
      userChallengeStatus: map['UserChallengeStatus'] ?? '',
      isOathTaken: map['IsOathTaken'] ?? false,
      challengeData: Map<String, dynamic>.from(map['ChallengeData'] ?? {}),
    );
  }

  /// Converts the [UserChallengeDetail] instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'UserChallengeId': userChallengeId,
      'UserChallengePledgeAmount': userChallengePledgeAmount,
      'UserChallengeStatus': userChallengeStatus,
      'IsOathTaken': isOathTaken,
      'ChallengeData': challengeData,
    };
  }
}
