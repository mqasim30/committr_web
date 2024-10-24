// lib/services/user_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Import for stream merging
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../screens/oath_screen.dart';
import '../services/log_service.dart';

/// Represents different types of user challenge events
enum UserChallengeEventType { added, updated, removed }

class UserChallengeEvent {
  final UserChallengeEventType type;
  final UserChallengeDetail? detail;
  final String? challengeId;

  UserChallengeEvent.added(this.detail)
      : type = UserChallengeEventType.added,
        challengeId = detail?.userChallengeId;

  UserChallengeEvent.updated(this.detail)
      : type = UserChallengeEventType.updated,
        challengeId = detail?.userChallengeId;

  UserChallengeEvent.removed(this.challengeId)
      : type = UserChallengeEventType.removed,
        detail = null;
}

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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

            // Extract challengeId safely
            String? challengeId = detail.userChallengeId;

            if (challengeId != null &&
                challengeId is String &&
                challengeId.isNotEmpty) {
              userChallenges[challengeId] = detail;
            } else {
              LogService.error(
                  "Invalid or missing 'challengeId' for userChallengeId: ${detail.userChallengeId}");
            }
          } catch (e, stackTrace) {
            LogService.error(
                "Error parsing user challenge data: $e", e, stackTrace);
          }
        });
        LogService.info("Fetched ${userChallenges.length} user challenges.");
      } else {
        LogService.info("No user challenges found for user.");
      }

      return userChallenges;
    } catch (error, stackTrace) {
      LogService.error(
          "Error fetching user challenges: $error", error, stackTrace);
      return {};
    }
  }

  /// Returns a stream of user challenge events for real-time updates
  Stream<UserChallengeEvent> getUserChallengesStream(String userId) {
    DatabaseReference userChallengesRef =
        _database.child('USER_PROFILES').child(userId).child('UserChallenges');

    // Stream for child added events
    final addedStream = userChallengesRef.onChildAdded
        .map((event) {
          if (event.snapshot.exists) {
            Map<String, dynamic> challengeMap =
                Map<String, dynamic>.from(event.snapshot.value as Map);
            UserChallengeDetail detail =
                UserChallengeDetail.fromMap(challengeMap);
            LogService.info(
                "User challenge added: ${detail.userChallengeId}, isOathTaken: ${detail.isOathTaken}");
            return UserChallengeEvent.added(detail);
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
            Map<String, dynamic> challengeMap =
                Map<String, dynamic>.from(event.snapshot.value as Map);
            UserChallengeDetail detail =
                UserChallengeDetail.fromMap(challengeMap);
            LogService.info(
                "User challenge updated: ${detail.userChallengeId}, isOathTaken: ${detail.isOathTaken}");
            return UserChallengeEvent.updated(detail);
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

  /// Attempts to join a challenge. Returns true if successful, false otherwise.
  Future<bool> joinChallenge(BuildContext context, String userId,
      Challenge challenge, double pledgeAmount) async {
    try {
      DatabaseReference userChallengeRef = _database
          .child('USER_PROFILES')
          .child(userId)
          .child('UserChallenges')
          .child(challenge.challengeId);

      // Check if the user has already joined the challenge
      DataSnapshot existingChallenge = await userChallengeRef.get();

      if (existingChallenge.exists) {
        LogService.warning(
            "User $userId has already joined challenge ${challenge.challengeId}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already joined this challenge.')),
        );
        return false;
      }

      // Create UserChallengeDetail with correct userChallengeId
      UserChallengeDetail userChallengeDetail = UserChallengeDetail(
        userChallengeId: challenge.challengeId, // Corrected assignment
        userChallengePledgeAmount: pledgeAmount,
        userChallengeStatus: 'In Progress',
        isOathTaken: false, // Remains false until oath is submitted
        challengeData: {}, // Initialize with empty map or any default data
      );

      // Save UserChallengeDetail
      await userChallengeRef.set(userChallengeDetail.toMap());

      // Increment participant count
      DatabaseReference challengeRef =
          _database.child('CHALLENGES').child(challenge.challengeId);

      int updatedParticipantCount = challenge.challengeNumberParticipants + 1;
      await challengeRef
          .child('ChallengeNumberParticipants')
          .set(updatedParticipantCount);

      // Append userId to challengeParticipantsId list
      DatabaseReference participantsRef =
          challengeRef.child('ChallengeParticipantsId');

      DataSnapshot participantsSnapshot = await participantsRef.get();

      List<dynamic> participantsList = participantsSnapshot.exists
          ? List<dynamic>.from(participantsSnapshot.value as List<dynamic>)
          : [];

      if (!participantsList.contains(userId)) {
        participantsList.add(userId);
        await participantsRef.set(participantsList);
      }

      LogService.info(
          "User $userId has joined challenge ${challenge.challengeId}");

      // Navigate to Oath Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OathScreen(
            userId: userId,
            challengeId: challenge.challengeId,
          ),
        ),
      );

      return true;
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to join challenge ${challenge.challengeId} for user $userId: $e",
          e,
          stackTrace);
      return false;
    }
  }

  /// Submits the oath for the user in a specific challenge
  Future<bool> submitOath(String userId, String challengeId) async {
    try {
      DatabaseReference userChallengeRef = _database
          .child('USER_PROFILES')
          .child(userId)
          .child('UserChallenges')
          .child(challengeId);

      await userChallengeRef.update({
        'IsOathTaken': true,
      });

      LogService.info(
          "Oath status updated successfully for user $userId in challenge $challengeId");

      return true;
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to update oath status for user $userId in challenge $challengeId: $e",
          e,
          stackTrace);
      return false;
    }
  }
}
