// lib/services/user_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_challenge_detail.dart';
import '../services/log_service.dart';

class UserService {
  final DatabaseReference _userProfilesRef =
      FirebaseDatabase.instance.ref().child('USER_PROFILES');

  UserService();

  /// Fetches the user's challenges and returns a map of challengeId to UserChallengeDetail
  Future<Map<String, UserChallengeDetail>> getUserChallenges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      LogService.error("No authenticated user found.");
      return {};
    }

    try {
      DatabaseReference userChallengesRef =
          _userProfilesRef.child(user.uid).child('UserChallenges');

      DataSnapshot snapshot = await userChallengesRef.get();

      Map<String, UserChallengeDetail> userChallenges = {};

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;
        challengesMap.forEach((key, value) {
          UserChallengeDetail detail = UserChallengeDetail.fromMap(
              Map<String, dynamic>.from(value as Map));
          userChallenges[detail.userChallengeId] = detail;
        });
        LogService.info("Fetched ${userChallenges.length} user challenges.");
      } else {
        LogService.info("No user challenges found for user.");
      }

      return userChallenges;
    } catch (error) {
      LogService.error("Error fetching user challenges: $error");
      return {};
    }
  }
}
