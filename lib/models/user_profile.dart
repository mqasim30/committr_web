// models/user_profile.dart

import 'user_challenge_detail.dart';

class UserProfile {
  final String userId;
  final String userName;
  final String userEmail;
  final String userIP;
  final String userCountry;
  final int userJoinDate;
  final int userActiveDate;
  final Map<String, UserChallengeDetail> userChallenges;
  final int userInvited;
  final String userInvitedBy;
  final String userSource;
  final String userStatus;
  final String platform;
  final double amountWon;
  final String? clickId;

  UserProfile({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userIP,
    required this.userCountry,
    required this.userJoinDate,
    required this.userActiveDate,
    required this.userChallenges,
    required this.userInvited,
    required this.userInvitedBy,
    required this.userSource,
    required this.userStatus,
    required this.platform,
    required this.amountWon,
    required this.clickId,
  });

  /// Creates a [UserProfile] instance from a Map.
  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    // Deserialize UserChallenges
    Map<String, UserChallengeDetail> challenges = {};
    if (map['UserChallenges'] != null) {
      map['UserChallenges'].forEach((key, value) {
        challenges[key] =
            UserChallengeDetail.fromMap(Map<dynamic, dynamic>.from(value));
      });
    }

    return UserProfile(
      userId: map['UserId'] ?? '',
      userName: map['UserName'] ?? '',
      userEmail: map['UserEmail'] ?? '',
      userIP: map['UserIP'] ?? '',
      userCountry: map['UserCountry'] ?? '',
      userJoinDate: map['UserJoinDate'] ?? 0,
      userActiveDate: map['UserActiveDate'] ?? 0,
      userChallenges: challenges,
      userInvited: map['UserInvited'] ?? 0,
      userInvitedBy: map['UserInvitedBy'] ?? '',
      userSource: map['UserSource'] ?? '',
      userStatus: map['UserStatus'] ?? '',
      platform: map['Platform'] ?? '',
      amountWon: (map['AmountWon'] ?? 0).toDouble(),
      clickId: map['ClickId'], // 🆕 Extract clickId from map
    );
  }

  /// Converts the [UserProfile] instance to a Map.
  Map<String, dynamic> toMap() {
    // Serialize UserChallenges
    Map<String, dynamic> challengesMap = {};
    userChallenges.forEach((key, value) {
      challengesMap[key] = value.toMap();
    });

    final map = {
      'UserId': userId,
      'UserName': userName,
      'UserEmail': userEmail,
      'UserIP': userIP,
      'UserCountry': userCountry,
      'UserJoinDate': userJoinDate,
      'UserActiveDate': userActiveDate,
      'UserChallenges': challengesMap,
      'UserInvited': userInvited,
      'UserInvitedBy': userInvitedBy,
      'UserSource': userSource,
      'UserStatus': userStatus,
      'Platform': platform,
      'AmountWon': amountWon,
    };

    // 🆕 Only add ClickId if it's not null
    if (clickId != null) {
      map['ClickId'] = clickId!;
    }

    return map;
  }
}
