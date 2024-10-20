// lib/widgets/challenge_listener.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';
import '../providers/challenge_provider.dart';
import '../services/challenge_service.dart';
import '../models/challenge.dart';

class ChallengeListener extends StatefulWidget {
  const ChallengeListener({Key? key}) : super(key: key);

  @override
  _ChallengeListenerState createState() => _ChallengeListenerState();
}

class _ChallengeListenerState extends State<ChallengeListener> {
  late final ChallengeProvider _challengeProvider;
  late final ChallengeService _challengeService;

  @override
  void initState() {
    super.initState();
    _challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    _challengeService = Provider.of<ChallengeService>(context, listen: false);

    _setupListeners();
  }

  /// Sets up real-time listeners for challenges
  void _setupListeners() {
    // Listener for when a new challenge is added
    _challengeService.challengesRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        Challenge newChallenge = Challenge.fromMap(
            Map<String, dynamic>.from(event.snapshot.value as Map));
        LogService.info("New Challenge Added: ${newChallenge.challengeTitle}");
        _challengeProvider.updateChallenges(); // Update provider data
      }
    }, onError: (error) {
      LogService.error("Error in childAdded listener: $error");
    });

    // Listener for when a challenge is changed
    _challengeService.challengesRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
        Challenge updatedChallenge = Challenge.fromMap(
            Map<String, dynamic>.from(event.snapshot.value as Map));
        LogService.info(
            "Challenge Updated: ${updatedChallenge.challengeTitle}");
        _challengeProvider.updateChallenges(); // Update provider data
      }
    }, onError: (error) {
      LogService.error("Error in childChanged listener: $error");
    });

    // Listener for when a challenge is removed
    _challengeService.challengesRef.onChildRemoved.listen((event) {
      if (event.snapshot.value != null) {
        Challenge removedChallenge = Challenge.fromMap(
            Map<String, dynamic>.from(event.snapshot.value as Map));
        LogService.info(
            "Challenge Removed: ${removedChallenge.challengeTitle}");
        _challengeProvider.updateChallenges(); // Update provider data
      }
    }, onError: (error) {
      LogService.error("Error in childRemoved listener: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    return Container();
  }
}
