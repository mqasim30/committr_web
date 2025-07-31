// lib/services/challenge_service.dart - OPTIMIZED VERSION

import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';
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

  // Cache to avoid repeated queries
  List<Challenge>? _cachedJoinableChallenges;
  DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 15);

  ChallengeService();

  /// Getter for challengesRef
  DatabaseReference get challengesRef => _challengesRef;

  /// 🚀 OPTIMIZED: Fetch only joinable challenges (massive cost savings)
  Future<List<Challenge>> fetchJoinableChallenges() async {
    try {
      // Check cache first
      if (_cachedJoinableChallenges != null &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheTimeout) {
        LogService.info(
            "Returning cached joinable challenges (${_cachedJoinableChallenges!.length} items)");
        return _cachedJoinableChallenges!;
      }

      LogService.info("Fetching joinable challenges from server...");

      // 🎯 EFFICIENT QUERY: Only fetch challenges where IsJoinable = true
      DataSnapshot snapshot =
          await _challengesRef.orderByChild('IsJoinable').equalTo(true).get();

      List<Challenge> joinableChallenges = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;

        challengesMap.forEach((key, value) {
          try {
            Challenge challenge =
                Challenge.fromMap(Map<String, dynamic>.from(value as Map));

            // Additional client-side filtering for active challenges only
            if (challenge.challengeState == 'Active') {
              joinableChallenges.add(challenge);
            }
          } catch (e) {
            LogService.error("Error parsing challenge $key: $e");
          }
        });

        // Sort by challenge order for consistent display
        joinableChallenges
            .sort((a, b) => a.challengeOrder.compareTo(b.challengeOrder));

        LogService.info(
            "Fetched ${joinableChallenges.length} joinable challenges.");
      } else {
        LogService.info("No joinable challenges found.");
      }

      // Update cache
      _cachedJoinableChallenges = joinableChallenges;
      _lastCacheTime = DateTime.now();

      return joinableChallenges;
    } catch (error) {
      LogService.error("Error fetching joinable challenges: $error");
      // Return cached data if available, otherwise empty list
      return _cachedJoinableChallenges ?? [];
    }
  }

  /// 🚀 OPTIMIZED: Fetch single challenge by ID (much more efficient)
  Future<Challenge?> fetchChallengeById(String challengeId) async {
    try {
      LogService.info("Fetching challenge by ID: $challengeId");

      DataSnapshot snapshot = await _challengesRef.child(challengeId).get();

      if (snapshot.exists) {
        Map<String, dynamic> challengeMap =
            Map<String, dynamic>.from(snapshot.value as Map);
        Challenge challenge = Challenge.fromMap(challengeMap);
        LogService.info("Successfully fetched challenge: $challengeId");
        return challenge;
      } else {
        LogService.info("Challenge not found: $challengeId");
        return null;
      }
    } catch (error) {
      LogService.error("Error fetching challenge by ID: $error");
      return null;
    }
  }

  /// 🚀 OPTIMIZED: Stream only for joinable challenges (not all challenges)
  Stream<ChallengeEvent> getJoinableChallengesStream() {
    // Create a query for only joinable challenges
    Query joinableChallengesQuery =
        _challengesRef.orderByChild('IsJoinable').equalTo(true);

    // Stream for child added events (only joinable challenges)
    final addedStream = joinableChallengesQuery.onChildAdded
        .map((event) {
          if (event.snapshot.exists) {
            try {
              Map<String, dynamic> challengeMap =
                  Map<String, dynamic>.from(event.snapshot.value as Map);
              Challenge challenge = Challenge.fromMap(challengeMap);

              // Only emit if challenge is also active
              if (challenge.challengeState == 'Active') {
                LogService.info(
                    "Joinable challenge added: ${challenge.challengeId}");
                return ChallengeEvent.added(challenge);
              }
            } catch (e) {
              LogService.error("Error parsing added challenge: $e");
            }
          }
          return null;
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Stream for child changed events (only joinable challenges)
    final updatedStream = joinableChallengesQuery.onChildChanged
        .map((event) {
          if (event.snapshot.exists) {
            try {
              Map<String, dynamic> challengeMap =
                  Map<String, dynamic>.from(event.snapshot.value as Map);
              Challenge challenge = Challenge.fromMap(challengeMap);
              LogService.info(
                  "Joinable challenge updated: ${challenge.challengeId}");

              // Clear cache when challenges are updated
              _invalidateCache();

              return ChallengeEvent.updated(challenge);
            } catch (e) {
              LogService.error("Error parsing updated challenge: $e");
            }
          }
          return null;
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Stream for child removed events (only joinable challenges)
    final removedStream = joinableChallengesQuery.onChildRemoved
        .map((event) {
          String? challengeId = event.snapshot.key;
          if (challengeId != null) {
            LogService.info("Joinable challenge removed: $challengeId");

            // Clear cache when challenges are removed
            _invalidateCache();

            return ChallengeEvent.removed(challengeId);
          }
          return null;
        })
        .where((event) => event != null)
        .cast<ChallengeEvent>();

    // Merge all streams
    return MergeStream<ChallengeEvent>(
        [addedStream, updatedStream, removedStream]);
  }

  /// Clear the cache manually
  void _invalidateCache() {
    _cachedJoinableChallenges = null;
    _lastCacheTime = null;
    LogService.info("Challenge cache invalidated");
  }

  /// Public method to clear cache
  void clearCache() {
    _invalidateCache();
  }

  /// Get cache status
  bool get hasCachedData => _cachedJoinableChallenges != null;

  DateTime? get lastCacheTime => _lastCacheTime;
}
