// lib/models/challenge.dart

class Challenge {
  final String challengeId;
  final int challengeOrder;
  final String challengeTitle;
  final String challengeCategory;
  final int challengeDurationDays;
  final String challengeState;
  final bool isJoinable;
  final String challengeDescription;
  final List<String> rules;
  final int challengeNumberParticipants;
  final double challengePotSize;
  final String platform;
  final int challengeStartTimestamp;
  final int challengeEndTimestamp;
  final List<String> challengeParticipantsId;
  final List<String> participantsProfilePictureUrl;

  Challenge({
    required this.challengeId,
    required this.challengeOrder,
    required this.challengeTitle,
    required this.challengeCategory,
    required this.challengeDurationDays,
    required this.challengeState,
    required this.isJoinable,
    required this.challengeDescription,
    required this.rules,
    required this.challengeNumberParticipants,
    required this.challengePotSize,
    required this.platform,
    required this.challengeStartTimestamp,
    required this.challengeEndTimestamp,
    required this.challengeParticipantsId,
    required this.participantsProfilePictureUrl,
  });

  /// Factory method to create a Challenge from a map
  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      challengeId: map['ChallengeId'] ?? '',
      challengeOrder: map['ChallengeOrder'] ?? 0,
      challengeTitle: map['ChallengeTitle'] ?? '',
      challengeCategory: map['ChallengeCategory'] ?? '',
      challengeDurationDays: map['ChallengeDurationDays'] ?? 0,
      challengeState: map['ChallengeState'] ?? '',
      isJoinable: map['IsJoinable'] ?? false,
      challengeDescription: map['ChallengeDescription'] ?? '',
      rules: List<String>.from(map['ChallengeRules'] ?? []),
      challengeNumberParticipants: map['ChallengeNumberParticipants'] ?? 0,
      challengePotSize: map['ChallengePotSize'] != null
          ? map['ChallengePotSize'].toDouble()
          : 0.0,
      platform: map['Platform'] ?? 'Web',
      challengeStartTimestamp: map['ChallengeStartTimestamp'] ?? 0,
      challengeEndTimestamp: map['ChallengeEndTimestamp'] ?? 0,
      challengeParticipantsId:
          List<String>.from(map['ChallengeParticipantsId'] ?? []),
      participantsProfilePictureUrl:
          List<String>.from(map['ParticipantsProfilePictureURL']),
    );
  }

  /// Converts Challenge object to Map
  Map<String, dynamic> toMap() {
    return {
      'ChallengeId': challengeId,
      'ChallengeOrder': challengeOrder,
      'ChallengeTitle': challengeTitle,
      'ChallengeCategory': challengeCategory,
      'ChallengeDurationDays': challengeDurationDays,
      'ChallengeState': challengeState,
      'IsJoinable': isJoinable,
      'ChallengeDescription': challengeDescription,
      'ChallengeRules': rules,
      'ChallengeNumberParticipants': challengeNumberParticipants,
      'ChallengePotSize': challengePotSize,
      'Platform': platform,
      'ChallengeStartTimestamp': challengeStartTimestamp,
      'ChallengeEndTimestamp': challengeEndTimestamp,
      'ChallengeParticipantsId': challengeParticipantsId,
      'ParticipantsProfilePictureURL': participantsProfilePictureUrl,
    };
  }
}
