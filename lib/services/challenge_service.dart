// lib/services/challenge_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart'; // Import for stream merging
import '../models/challenge.dart';
import '../services/log_service.dart';

/// Represents different types of challenge events
enum ChallengeEventType { added, updated, removed }

class ChallengeEvent {
  final ChallengeEventType type;
  final Challenge? challenge;
  final String? challengeId;

  ChallengeEvent.added(this.challenge)
      : type = ChallengeEventType.added,
        challengeId = null;

  ChallengeEvent.updated(this.challenge)
      : type = ChallengeEventType.updated,
        challengeId = null;

  ChallengeEvent.removed(this.challengeId)
      : type = ChallengeEventType.removed,
        challenge = null;
}

class ChallengeService {
  final DatabaseReference _challengesRef =
      FirebaseDatabase.instance.ref().child('CHALLENGES');

  ChallengeService();

  /// Getter for challengesRef
  DatabaseReference get challengesRef => _challengesRef;

  /// Fetches all challenges from the Realtime Database
  Future<List<Challenge>> fetchAllChallenges() async {
    try {
      DataSnapshot snapshot = await _challengesRef.get();
      List<Challenge> allChallenges = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;
        challengesMap.forEach((key, value) {
          Challenge challenge =
              Challenge.fromMap(Map<String, dynamic>.from(value as Map));
          allChallenges.add(challenge);
        });
        LogService.info("Fetched ${allChallenges.length} challenges.");
      } else {
        LogService.info("No challenges found.");
      }
      return allChallenges;
    } catch (error) {
      LogService.error("Error fetching challenges: $error");
      return [];
    }
  }

  /// Returns a stream of all challenges for real-time updates
  Stream<ChallengeEvent> getChallengesStream() {
    // Stream for child added events
    final addedStream = _challengesRef.onChildAdded
        .map((event) {
          if (event.snapshot.exists) {
            Map<String, dynamic> challengeMap =
                Map<String, dynamic>.from(event.snapshot.value as Map);
            Challenge challenge = Challenge.fromMap(challengeMap);
            LogService.info("Challenge added: ${challenge.challengeId}");
            return ChallengeEvent.added(challenge);
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Stream for child changed events
    final updatedStream = _challengesRef.onChildChanged
        .map((event) {
          if (event.snapshot.exists) {
            Map<String, dynamic> challengeMap =
                Map<String, dynamic>.from(event.snapshot.value as Map);
            Challenge challenge = Challenge.fromMap(challengeMap);
            LogService.info("Challenge updated: ${challenge.challengeId}");
            return ChallengeEvent.updated(challenge);
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Stream for child removed events
    final removedStream = _challengesRef.onChildRemoved
        .map((event) {
          String? challengeId = event.snapshot.key;
          if (challengeId != null) {
            LogService.info("Challenge removed: $challengeId");
            return ChallengeEvent.removed(challengeId);
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Merge all streams into a single stream
    return MergeStream<ChallengeEvent>(
        [addedStream, updatedStream, removedStream]);
  }
}
