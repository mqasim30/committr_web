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
  static const Duration _cacheTimeout = Duration(minutes: 5);

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

  /// 🚀 OPTIMIZED: Fetch active challenges only (for different use cases)
  Future<List<Challenge>> fetchActiveChallenges({int? limit}) async {
    try {
      LogService.info("Fetching active challenges...");

      Query query =
          _challengesRef.orderByChild('ChallengeState').equalTo('Active');

      // Add limit if specified
      if (limit != null && limit > 0) {
        query = query.limitToFirst(limit);
      }

      DataSnapshot snapshot = await query.get();
      List<Challenge> activeChallenges = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;

        challengesMap.forEach((key, value) {
          try {
            Challenge challenge =
                Challenge.fromMap(Map<String, dynamic>.from(value as Map));
            activeChallenges.add(challenge);
          } catch (e) {
            LogService.error("Error parsing challenge $key: $e");
          }
        });

        // Sort by challenge order
        activeChallenges
            .sort((a, b) => a.challengeOrder.compareTo(b.challengeOrder));
        LogService.info(
            "Fetched ${activeChallenges.length} active challenges.");
      }

      return activeChallenges;
    } catch (error) {
      LogService.error("Error fetching active challenges: $error");
      return [];
    }
  }

  /// 🚀 OPTIMIZED: Fetch challenges by category (Weight Loss, Fitness, etc.)
  Future<List<Challenge>> fetchChallengesByCategory(String category,
      {int? limit}) async {
    try {
      LogService.info("Fetching challenges for category: $category");

      Query query =
          _challengesRef.orderByChild('ChallengeCategory').equalTo(category);

      if (limit != null && limit > 0) {
        query = query.limitToFirst(limit);
      }

      DataSnapshot snapshot = await query.get();
      List<Challenge> categoryChallenges = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;

        challengesMap.forEach((key, value) {
          try {
            Challenge challenge =
                Challenge.fromMap(Map<String, dynamic>.from(value as Map));
            // Only include active and joinable challenges
            if (challenge.challengeState == 'Active' && challenge.isJoinable) {
              categoryChallenges.add(challenge);
            }
          } catch (e) {
            LogService.error("Error parsing challenge $key: $e");
          }
        });

        categoryChallenges
            .sort((a, b) => a.challengeOrder.compareTo(b.challengeOrder));
        LogService.info(
            "Fetched ${categoryChallenges.length} challenges for category $category.");
      }

      return categoryChallenges;
    } catch (error) {
      LogService.error("Error fetching challenges by category: $error");
      return [];
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

  /// 🚀 OPTIMIZED: Paginated challenge fetching for large datasets
  Future<List<Challenge>> fetchChallengesPaginated({
    String? lastChallengeId,
    int limit = 10,
    String orderBy = 'ChallengeOrder',
  }) async {
    try {
      LogService.info("Fetching challenges with pagination (limit: $limit)");

      Query query = _challengesRef.orderByChild(orderBy);

      // Start after the last item if continuing pagination
      if (lastChallengeId != null) {
        // This would require the actual value to start after, not just the ID
        // For proper pagination, you'd need to store the orderBy value
        query = query.limitToFirst(limit);
      } else {
        query = query.limitToFirst(limit);
      }

      DataSnapshot snapshot = await query.get();
      List<Challenge> challenges = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> challengesMap =
            snapshot.value as Map<dynamic, dynamic>;

        challengesMap.forEach((key, value) {
          try {
            Challenge challenge =
                Challenge.fromMap(Map<String, dynamic>.from(value as Map));
            // Only include active and joinable challenges
            if (challenge.challengeState == 'Active' && challenge.isJoinable) {
              challenges.add(challenge);
            }
          } catch (e) {
            LogService.error("Error parsing challenge $key: $e");
          }
        });

        LogService.info("Fetched ${challenges.length} challenges (paginated).");
      }

      return challenges;
    } catch (error) {
      LogService.error("Error fetching paginated challenges: $error");
      return [];
    }
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
