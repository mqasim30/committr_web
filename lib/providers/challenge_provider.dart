// lib/providers/challenge_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../services/challenge_service.dart';
import '../services/user_service.dart';
import '../services/log_service.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _availableChallenges = [];
  List<Challenge> _activeChallenges = [];
  Map<String, UserChallengeDetail> _userChallenges = {};

  final ChallengeService _challengeService;
  final UserService _userService;

  // Subscriptions to streams
  late StreamSubscription<ChallengeEvent> _challengesSubscription;
  late StreamSubscription<UserChallengeEvent> _userChallengesSubscription;

  bool _initialized = false;

  ChallengeProvider(this._challengeService, this._userService);

  List<Challenge> get availableChallenges => _availableChallenges;
  List<Challenge> get activeChallenges => _activeChallenges;
  Map<String, UserChallengeDetail> get userChallenges => _userChallenges;

  /// Initializes the provider by fetching challenges and setting up listeners.
  Future<void> initialize() async {
    if (_initialized) {
      LogService.info("ChallengeProvider is already initialized.");
      return;
    }
    _initialized = true;

    LogService.info("Initializing ChallengeProvider.");
    await _fetchInitialData();
    _listenToChallenges();
    _listenToUserChallenges();
  }

  /// Fetches initial challenges and user challenges
  Future<void> _fetchInitialData() async {
    LogService.info("Fetching initial challenges.");
    List<Challenge> allChallenges =
        await _challengeService.fetchAllChallenges();

    LogService.info("Fetching initial user challenges.");
    User? currentUser = _userService.getCurrentUser();
    if (currentUser != null) {
      _userChallenges = await _userService.getUserChallenges();
    } else {
      _userChallenges = {};
    }

    _categorizeChallenges(allChallenges);
    notifyListeners();
  }

  /// Categorizes challenges into available and active based on user participation
  void _categorizeChallenges(List<Challenge> allChallenges) {
    _availableChallenges = allChallenges
        .where((challenge) =>
            !_userChallenges.containsKey(challenge.challengeId) &&
            challenge.isJoinable &&
            !_availableChallenges
                .any((c) => c.challengeId == challenge.challengeId))
        .toList();

    _activeChallenges = allChallenges
        .where((challenge) =>
            _userChallenges.containsKey(challenge.challengeId) &&
            (_userChallenges[challenge.challengeId]!.userChallengeStatus ==
                    "In Progress" ||
                _userChallenges[challenge.challengeId]!.userChallengeStatus ==
                    "Submission") &&
            !_activeChallenges
                .any((c) => c.challengeId == challenge.challengeId))
        .toList();
  }

  /// Listens to the global challenges stream for real-time updates
  void _listenToChallenges() {
    _challengesSubscription =
        _challengeService.getChallengesStream().listen((event) {
      switch (event.type) {
        case ChallengeEventType.added:
          _handleChallengeAdded(event.challenge!);
          break;
        case ChallengeEventType.updated:
          _handleChallengeUpdated(event.challenge!);
          break;
        case ChallengeEventType.removed:
          _handleChallengeRemoved(event.challengeId!);
          break;
      }
    }, onError: (error) {
      LogService.error("Error in challenges stream: $error");
    });
  }

  /// Handles a challenge being added
  void _handleChallengeAdded(Challenge challenge) {
    LogService.info("Handling added challenge: ${challenge.challengeId}");
    // If user hasn't joined and it's joinable, and not already in the list, add to available
    if (!_userChallenges.containsKey(challenge.challengeId) &&
        challenge.isJoinable &&
        !_availableChallenges
            .any((c) => c.challengeId == challenge.challengeId)) {
      _availableChallenges.add(challenge);
      notifyListeners();
    }
  }

  /// Handles a challenge being updated
  void _handleChallengeUpdated(Challenge challenge) {
    LogService.info("Handling updated challenge: ${challenge.challengeId}");

    // Check if challenge is in available challenges
    int availIndex = _availableChallenges
        .indexWhere((c) => c.challengeId == challenge.challengeId);

    if (availIndex != -1) {
      if (challenge.isJoinable) {
        // Update the challenge in available challenges
        _availableChallenges[availIndex] = challenge;
      } else {
        // Remove the challenge from available challenges
        _availableChallenges.removeAt(availIndex);
      }
      notifyListeners();
    }

    // Check if challenge is in active challenges
    int activeIndex = _activeChallenges
        .indexWhere((c) => c.challengeId == challenge.challengeId);

    if (activeIndex != -1) {
      // Update the challenge in active challenges
      _activeChallenges[activeIndex] = challenge;
      notifyListeners();
    }

    // If challenge is not in any list, determine where to add it
    if (availIndex == -1 && activeIndex == -1) {
      if (!_userChallenges.containsKey(challenge.challengeId) &&
          challenge.isJoinable) {
        // Add to available challenges
        _availableChallenges.add(challenge);
        notifyListeners();
      } else if (_userChallenges.containsKey(challenge.challengeId)) {
        // User has joined this challenge, add to active challenges
        _activeChallenges.add(challenge);
        notifyListeners();
      }
    }
  }

  /// Handles a challenge being removed
  void _handleChallengeRemoved(String challengeId) {
    LogService.info("Handling removed challenge: $challengeId");
    _availableChallenges
        .removeWhere((challenge) => challenge.challengeId == challengeId);
    _activeChallenges
        .removeWhere((challenge) => challenge.challengeId == challengeId);
    notifyListeners();
  }

  /// Listens to the user's challenges stream for real-time updates
  void _listenToUserChallenges() {
    User? currentUser = _userService.getCurrentUser();
    if (currentUser == null) {
      LogService.error("No authenticated user found for setting up listener.");
      return;
    }

    _userChallengesSubscription =
        _userService.getUserChallengesStream(currentUser.uid).listen((event) {
      if (event.type == UserChallengeEventType.added ||
          event.type == UserChallengeEventType.updated) {
        if (event.detail != null && event.challengeId != null) {
          _userChallenges[event.challengeId!] = event.detail!;
          LogService.info(
              "User challenge updated: ${event.challengeId}, isOathTaken: ${event.detail!.isOathTaken}");
        }
      } else if (event.type == UserChallengeEventType.removed) {
        if (event.challengeId != null) {
          _userChallenges.remove(event.challengeId!);
          LogService.info("User challenge removed: ${event.challengeId}");
        }
      }

      // Re-categorize challenges based on updated user challenges
      _reCategorizeBasedOnUserChallenges();
      notifyListeners();
    }, onError: (error) {
      LogService.error("Error in user challenges stream: $error");
    });
  }

  /// Re-categorizes challenges when user challenges are updated
  void _reCategorizeBasedOnUserChallenges() {
    LogService.info("Re-categorizing challenges based on user challenges.");

    // Remove available challenges that the user has now joined
    _availableChallenges.removeWhere(
        (challenge) => _userChallenges.containsKey(challenge.challengeId));

    // Remove active challenges that the user is no longer participating in
    _activeChallenges.removeWhere(
        (challenge) => !_userChallenges.containsKey(challenge.challengeId));

    // Add to active challenges if not already present
    _userChallenges.forEach((challengeId, userChallengeDetail) {
      if (!_activeChallenges.any((c) => c.challengeId == challengeId)) {
        // Fetch the challenge from challengeService
        _challengeService.fetchChallengeById(challengeId).then((challenge) {
          if (challenge != null) {
            _activeChallenges.add(challenge);
            notifyListeners();
          }
        });
      }
    });

    notifyListeners();
  }

  /// Disposes of all subscriptions to prevent memory leaks
  @override
  void dispose() {
    _challengesSubscription.cancel();
    _userChallengesSubscription.cancel();
    super.dispose();
  }
}
