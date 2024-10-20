// lib/services/challenge_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/challenge.dart';
import '../services/log_service.dart';

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
}
