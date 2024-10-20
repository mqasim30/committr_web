// lib/providers/challenge_provider.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/challenge_categorization.dart';
import '../services/log_service.dart';

class ChallengeProvider with ChangeNotifier {
  List<Challenge> _availableChallenges = [];
  List<Challenge> _activeChallenges = [];

  List<Challenge> get availableChallenges => _availableChallenges;
  List<Challenge> get activeChallenges => _activeChallenges;

  final ChallengeCategorization _categorization;
  bool _isFetching = false; // Guard flag

  ChallengeProvider(this._categorization) {
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    if (_isFetching) {
      LogService.info("Fetch already in progress. Skipping.");
      return;
    }
    _isFetching = true;
    LogService.info("Starting fetchChallenges at ${DateTime.now()}");
    try {
      _availableChallenges = await _categorization.getAvailableChallenges();
      _activeChallenges = await _categorization.getActiveChallenges();
      notifyListeners();
      LogService.info("Completed fetchChallenges at ${DateTime.now()}");
    } catch (e) {
      LogService.error("Error in _fetchChallenges: $e");
    } finally {
      _isFetching = false;
    }
  }

  /// Call this method whenever challenges are updated
  Future<void> updateChallenges() async {
    await _fetchChallenges();
  }
}
