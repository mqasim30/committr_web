// lib/services/user_service.dart - SECURE VERSION

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_challenge_detail.dart';
import '../services/log_service.dart';

/// Represents different types of user challenge events
enum UserChallengeEventType { added, updated, removed }

class UserChallengeEvent {
  final UserChallengeEventType type;
  final UserChallengeDetail? detail;
  final String? challengeId;

  UserChallengeEvent.added(this.detail, this.challengeId)
      : type = UserChallengeEventType.added;

  UserChallengeEvent.updated(this.detail, this.challengeId)
      : type = UserChallengeEventType.updated;

  UserChallengeEvent.removed(this.challengeId)
      : type = UserChallengeEventType.removed,
        detail = null;
}

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  UserService();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Fetches the user's challenges and returns a map of challengeId to UserChallengeDetail
  Future<Map<String, UserChallengeDetail>> getUserChallenges() async {
    User? user = getCurrentUser();
    if (user == null) {
      LogService.error("No authenticated user found.");
      return {};
    }

    try {
      DatabaseReference userChallengesRef = _database
          .child('USER_PROFILES')
          .child(user.uid)
          .child('UserChallenges');

      DataSnapshot snapshot = await userChallengesRef.get();

      Map<String, UserChallengeDetail> userChallenges = {};

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;
        challengesMap.forEach((key, value) {
          try {
            UserChallengeDetail detail = UserChallengeDetail.fromMap(
                Map<String, dynamic>.from(value as Map));

            // Ensure userChallengeId is set to challengeId
            if (detail.userChallengeId.isEmpty) {
              detail = UserChallengeDetail(
                userChallengeId: key, // Set to challengeId
                userChallengePledgeAmount: detail.userChallengePledgeAmount,
                userChallengeStatus: detail.userChallengeStatus,
                isOathTaken: detail.isOathTaken,
                challengeData: detail.challengeData,
              );
            }

            userChallenges[key] = detail;
          } catch (e) {
            LogService.error("Error parsing user challenge $key: $e");
          }
        });
      }
      LogService.info("Fetched ${userChallenges.length} user challenges.");
      return userChallenges;
    } catch (error, stackTrace) {
      LogService.error(
          "Error fetching user challenges: $error", error, stackTrace);
      return {};
    }
  }

  /// Returns a stream of user challenge events for real-time updates
  Stream<UserChallengeEvent> getUserChallengesStream(String userId) {
    // Validate userId
    if (userId.isEmpty || getCurrentUser()?.uid != userId) {
      LogService.error("Invalid userId for stream");
      return Stream.empty();
    }

    DatabaseReference userChallengesRef =
        _database.child('USER_PROFILES').child(userId).child('UserChallenges');

    // Stream for child added events
    final addedStream = userChallengesRef.onChildAdded
        .map((event) {
          if (event.snapshot.exists) {
            try {
              Map<String, dynamic> challengeMap =
                  Map<String, dynamic>.from(event.snapshot.value as Map);
              UserChallengeDetail detail =
                  UserChallengeDetail.fromMap(challengeMap);

              // Ensure userChallengeId is set to challengeId
              if (detail.userChallengeId.isEmpty) {
                detail = UserChallengeDetail(
                  userChallengeId: event.snapshot.key!, // Set to challengeId
                  userChallengePledgeAmount: detail.userChallengePledgeAmount,
                  userChallengeStatus: detail.userChallengeStatus,
                  isOathTaken: detail.isOathTaken,
                  challengeData: detail.challengeData,
                );
              }

              return UserChallengeEvent.added(detail, event.snapshot.key!);
            } catch (e) {
              LogService.error("Error parsing added challenge: $e");
              return null;
            }
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<UserChallengeEvent>();

    // Stream for child changed events
    final updatedStream = userChallengesRef.onChildChanged
        .map((event) {
          if (event.snapshot.exists) {
            try {
              Map<String, dynamic> challengeMap =
                  Map<String, dynamic>.from(event.snapshot.value as Map);
              UserChallengeDetail detail =
                  UserChallengeDetail.fromMap(challengeMap);

              // Ensure userChallengeId is set to challengeId
              if (detail.userChallengeId.isEmpty) {
                detail = UserChallengeDetail(
                  userChallengeId: event.snapshot.key!, // Set to challengeId
                  userChallengePledgeAmount: detail.userChallengePledgeAmount,
                  userChallengeStatus: detail.userChallengeStatus,
                  isOathTaken: detail.isOathTaken,
                  challengeData: detail.challengeData,
                );
              }

              return UserChallengeEvent.updated(detail, event.snapshot.key!);
            } catch (e) {
              LogService.error("Error parsing updated challenge: $e");
              return null;
            }
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<UserChallengeEvent>();

    // Stream for child removed events
    final removedStream = userChallengesRef.onChildRemoved
        .map((event) {
          String? challengeId = event.snapshot.key;
          if (challengeId != null) {
            LogService.info("User challenge removed: $challengeId");
            return UserChallengeEvent.removed(challengeId);
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<UserChallengeEvent>();

    // Merge all streams into a single stream
    return MergeStream<UserChallengeEvent>(
        [addedStream, updatedStream, removedStream]);
  }

  /// Submit oath using secure Cloud Function
  Future<bool> submitOath({
    required String challengeId,
    required Map<String, dynamic> oathData,
  }) async {
    User? user = getCurrentUser();
    if (user == null) {
      LogService.error("No authenticated user found for oath submission");
      return false;
    }

    try {
      // Validate inputs
      if (challengeId.isEmpty) {
        throw Exception('Invalid challenge ID');
      }

      // Call secure Cloud Function
      HttpsCallable callable = _functions.httpsCallable('submitOath');

      final result = await callable.call({
        'challengeId': challengeId,
        'oathData': oathData,
      });

      if (result.data['success'] == true) {
        LogService.info(
            "Oath submitted successfully for challenge $challengeId");
        return true;
      } else {
        LogService.error("Oath submission failed: ${result.data['message']}");
        return false;
      }
    } catch (e, stackTrace) {
      LogService.error("Error submitting oath: $e", e, stackTrace);
      return false;
    }
  }

  /// Submit daily check-in using secure Cloud Function
  Future<bool> submitCheckIn({required String challengeId}) async {
    User? user = getCurrentUser();
    if (user == null) {
      LogService.error("No authenticated user found for check-in");
      return false;
    }

    try {
      // Validate input
      if (challengeId.isEmpty) {
        throw Exception('Invalid challenge ID');
      }

      // Call secure Cloud Function
      HttpsCallable callable = _functions.httpsCallable('submitCheckIn');

      final result = await callable.call({
        'challengeId': challengeId,
      });

      if (result.data['success'] == true) {
        LogService.info(
            "Check-in submitted successfully for challenge $challengeId");
        return true;
      } else {
        LogService.error("Check-in failed: ${result.data['message']}");
        return false;
      }
    } catch (e, stackTrace) {
      LogService.error("Error submitting check-in: $e", e, stackTrace);
      return false;
    }
  }
}
