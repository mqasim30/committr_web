// lib/providers/challenge_provider.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/challenge_categorization.dart';

class ChallengeProvider with ChangeNotifier {
  List<Challenge> _availableChallenges = [];
  List<Challenge> _activeChallenges = [];

  List<Challenge> get availableChallenges => _availableChallenges;
  List<Challenge> get activeChallenges => _activeChallenges;

  final ChallengeCategorization _categorization;

  ChallengeProvider(this._categorization) {
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    _availableChallenges = await _categorization.getAvailableChallenges();
    _activeChallenges = await _categorization.getActiveChallenges();
    notifyListeners();
  }

  /// Call this method whenever challenges are updated
  Future<void> updateChallenges() async {
    await _fetchChallenges();
  }
}
