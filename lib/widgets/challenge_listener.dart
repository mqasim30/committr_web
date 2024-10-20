// lib/widgets/challenge_listener.dart

import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';
import '../providers/challenge_provider.dart';
import '../services/challenge_service.dart';

class ChallengeListener extends StatefulWidget {
  const ChallengeListener({Key? key}) : super(key: key);

  @override
  _ChallengeListenerState createState() => _ChallengeListenerState();
}

class _ChallengeListenerState extends State<ChallengeListener> {
  late final ChallengeProvider _challengeProvider;
  late final ChallengeService _challengeService;

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    _challengeService = Provider.of<ChallengeService>(context, listen: false);

    _setupListeners();
  }

  /// Sets up real-time listeners for challenges with debouncing
  void _setupListeners() {
    // Listener for when a new challenge is added
    _challengeService.challengesRef.onChildAdded.listen((event) {
      _handleChallengeEvent("childAdded", event);
    }, onError: (error) {
      LogService.error("Error in childAdded listener: $error");
    });

    // Listener for when a challenge is changed
    _challengeService.challengesRef.onChildChanged.listen((event) {
      _handleChallengeEvent("childChanged", event);
    }, onError: (error) {
      LogService.error("Error in childChanged listener: $error");
    });

    // Listener for when a challenge is removed
    _challengeService.challengesRef.onChildRemoved.listen((event) {
      _handleChallengeEvent("childRemoved", event);
    }, onError: (error) {
      LogService.error("Error in childRemoved listener: $error");
    });
  }

  /// Handles challenge events with debouncing
  void _handleChallengeEvent(String eventType, event) {
    if (event.snapshot.value != null) {
      // Log the event
      LogService.info("Challenge event: $eventType");

      // Cancel any existing timer
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

      // Start a new debounce timer
      _debounceTimer = Timer(_debounceDuration, () {
        LogService.info("Debounced updateChallenges call");
        _challengeProvider.updateChallenges();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    return Container();
  }
}
