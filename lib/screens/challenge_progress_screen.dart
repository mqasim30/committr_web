// lib/screens/challenge_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import '../utils/challenge_helper.dart';
import '../services/log_service.dart'; // Import LogService
import 'dart:convert'; // For jsonEncode
import '../services/server_time_service.dart'; // Import ServerTimeService

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  _ChallengeProgressScreenState createState() =>
      _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  DateTime? _currentDate;

  @override
  void initState() {
    super.initState();
    _fetchServerTime();
  }

  Future<void> _fetchServerTime() async {
    try {
      DateTime serverTime = await ServerTimeService.getServerTime();
      setState(() {
        _currentDate = serverTime;
      });
    } catch (e) {
      LogService.error("Error fetching server time: $e");
      // Handle error appropriately, maybe set a default time or show an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final userChallengeDetail =
        challengeProvider.userChallenges[widget.challenge.challengeId];

    // Log the entire userChallengeDetail
    LogService.info(
        "UserChallengeDetail for challengeId ${widget.challenge.challengeId}: ${userChallengeDetail != null ? jsonEncode(userChallengeDetail.toMap()) : 'null'}");

    if (userChallengeDetail == null) {
      LogService.info(
          "UserChallengeDetail is null for challengeId: ${widget.challenge.challengeId}");
      return Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Progress'),
        ),
        body: const Center(
          child: Text('You have not joined this challenge yet.'),
        ),
      );
    }

    if (_currentDate == null) {
      // Show loading indicator while fetching server time
      return Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Progress'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final challengeType =
        ChallengeHelper.getChallengeType(widget.challenge.challengeTitle);

    LogService.info("Challenge Type: $challengeType");

    // Retrieve weights as doubles
    final startingWeight = userChallengeDetail.challengeData['startingWeight'];
    final currentWeight = userChallengeDetail.challengeData['currentWeight'];
    final weightUnit = userChallengeDetail.challengeData['weightUnit'] ??
        'kg'; // Default to kg

    LogService.info("startingWeight from challengeData: $startingWeight");
    LogService.info("currentWeight from challengeData: $currentWeight");
    LogService.info("weightUnit from challengeData: $weightUnit");

    if (startingWeight == null || currentWeight == null) {
      LogService.error(
          "Weight data is missing. startingWeight or currentWeight is null.");
      return Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Progress'),
        ),
        body: const Center(
          child:
              Text('Weight data is not available yet. Please try again later.'),
        ),
      );
    }

    // Convert weights to double if they are not already
    double? startingWeightValue;
    double? currentWeightValue;

    if (startingWeight is double) {
      startingWeightValue = startingWeight;
    } else if (startingWeight is int) {
      startingWeightValue = startingWeight.toDouble();
    } else {
      startingWeightValue = double.tryParse(startingWeight.toString());
    }

    if (currentWeight is double) {
      currentWeightValue = currentWeight;
    } else if (currentWeight is int) {
      currentWeightValue = currentWeight.toDouble();
    } else {
      currentWeightValue = double.tryParse(currentWeight.toString());
    }

    LogService.info("Parsed startingWeightValue: $startingWeightValue");
    LogService.info("Parsed currentWeightValue: $currentWeightValue");

    if (startingWeightValue == null || currentWeightValue == null) {
      LogService.error(
          "Failed to parse weights. startingWeightValue or currentWeightValue is null.");
      return Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Progress'),
        ),
        body: const Center(
          child:
              Text('Weight data is invalid. Please check your weight entries.'),
        ),
      );
    }

    final startDateTimestamp =
        widget.challenge.challengeStartTimestamp; // From Challenge object
    final endDateTimestamp =
        widget.challenge.challengeEndTimestamp; // From Challenge object
    final startDate =
        DateTime.fromMillisecondsSinceEpoch(startDateTimestamp, isUtc: false);
    final endDate =
        DateTime.fromMillisecondsSinceEpoch(endDateTimestamp, isUtc: false);
    final currentDate = _currentDate!;

    final progress =
        ChallengeHelper.calculateProgress(startDate, endDate, currentDate);
    final daysLeft = ChallengeHelper.calculateDaysLeft(endDate, currentDate);
    final goalWeight =
        ChallengeHelper.calculateGoalWeight(challengeType, startingWeightValue);

    LogService.info("Progress: $progress");
    LogService.info("Days Left: $daysLeft");
    LogService.info("Goal Weight: $goalWeight");

    // For Maintain Weight, define a range
    Map<String, double>? weightRange;
    if (challengeType == ChallengeType.MaintainWeight && goalWeight != null) {
      weightRange = ChallengeHelper.calculateMaintainWeightRange(goalWeight);
      LogService.info("Weight Range: $weightRange");
    }

    // Format dates for display
    final formattedStartDate = DateFormat.yMMMd().format(startDate);
    final formattedEndDate = DateFormat.yMMMd().format(endDate);

    // Adjust goalWeight and weightRange for units if needed
    double? adjustedGoalWeight = goalWeight;
    Map<String, double>? adjustedWeightRange = weightRange;

    if (weightUnit == 'lb') {
      // Convert kg to lb
      if (adjustedGoalWeight != null) {
        adjustedGoalWeight = adjustedGoalWeight * 2.20462;
      }
      if (adjustedWeightRange != null) {
        adjustedWeightRange = {
          'lower': adjustedWeightRange['lower']! * 2.20462,
          'upper': adjustedWeightRange['upper']! * 2.20462,
        };
      }
      LogService.info(
          "Adjusted Goal Weight for lb: $adjustedGoalWeight, Adjusted Weight Range: $adjustedWeightRange");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Timeline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Date: $formattedStartDate',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'End Date: $formattedEndDate',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Bar
            const Text(
              'Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 5),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% completed',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Days Left
            Text(
              'Days Left: $daysLeft',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            // Current Weight
            Text(
              'Current Weight: ${currentWeightValue.toStringAsFixed(1)} $weightUnit',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Starting Weight
            Text(
              'Starting Weight: ${startingWeightValue.toStringAsFixed(1)} $weightUnit',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Goal Weight
            if (challengeType != ChallengeType.MaintainWeight &&
                adjustedGoalWeight != null)
              Text(
                'Goal Weight: ${adjustedGoalWeight.toStringAsFixed(1)} $weightUnit',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            else if (challengeType == ChallengeType.MaintainWeight &&
                adjustedWeightRange != null)
              Text(
                'Maintain Weight between ${adjustedWeightRange['lower']!.toStringAsFixed(1)} $weightUnit and ${adjustedWeightRange['upper']!.toStringAsFixed(1)} $weightUnit',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 30),

            // Optional: Additional Challenge Details
            const Text(
              'Challenge Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.challenge.challengeDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Rules
            const Text(
              'Rules:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...widget.challenge.rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  rule,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
