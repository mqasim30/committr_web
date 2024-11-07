import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/constants.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import '../services/server_time_service.dart';
import '../utils/challenge_helper.dart';
import '../services/log_service.dart';
import '../widgets/rules_card.dart';
import '../widgets/custom_progress_bar.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final userChallengeDetail =
        challengeProvider.userChallenges[widget.challenge.challengeId];

    if (_currentDate == null || userChallengeDetail == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Retrieve weight data
    final startingWeight = userChallengeDetail.challengeData['startingWeight'];
    final currentWeight = userChallengeDetail.challengeData['currentWeight'];
    final weightUnit = userChallengeDetail.challengeData['weightUnit'] ?? 'kg';
    final challengeType =
        ChallengeHelper.getChallengeType(widget.challenge.challengeTitle);

    // Check and parse weight data
    double? startingWeightValue = _parseWeight(startingWeight);
    double? currentWeightValue = _parseWeight(currentWeight);

    final startDate = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeStartTimestamp);
    final endDate = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeEndTimestamp);
    final currentDate = _currentDate!;
    final progress =
        ChallengeHelper.calculateProgress(startDate, endDate, currentDate);
    final daysLeft = ChallengeHelper.calculateDaysLeft(endDate, currentDate);
    final goalWeight = ChallengeHelper.calculateGoalWeight(
        challengeType, startingWeightValue!);

    // Adjust weight units if needed
    final adjustedGoalWeight =
        weightUnit == 'lb' ? goalWeight! * 2.20462 : goalWeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header
            _buildHeader(context),

            const SizedBox(height: 16),

            // Challenge Description Card
            _buildDescriptionCard(widget.challenge),

            const SizedBox(height: 16),

            // Weight Information using cards
            _buildWeightInfo(
              currentWeight: currentWeightValue,
              startingWeight: startingWeightValue,
              goalWeight: adjustedGoalWeight,
              weightUnit: weightUnit,
              daysLeft: daysLeft,
              challengeType: challengeType,
            ),

            const SizedBox(height: 20),

            // Challenge Progress Bar
            const Text(
              'Progress',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.mainFGColor),
            ),
            const SizedBox(height: 10),
            CustomProgressBar(progress: progress), // Custom progress widget
            const SizedBox(height: 20),

            // Rules Section
            const Text(
              'Rules:',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: AppColors.mainFGColor),
            ),
            const SizedBox(height: 10),
            ...widget.challenge.rules.asMap().entries.map(
                  (entry) => RulesCard(
                    ruleText: entry.value,
                    ruleIndex: entry.key,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Helper function to parse weights
  double? _parseWeight(dynamic weight) {
    if (weight is double) return weight;
    if (weight is int) return weight.toDouble();
    return double.tryParse(weight.toString());
  }

  // Custom Header Builder
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircleIconButton(context, Icons.arrow_back, () {
          Navigator.pop(context);
        }),
        Expanded(
          child: Column(
            children: [
              Text(
                'Challenge:',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: AppColors.mainFGColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.challenge.challengeTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: AppColors.mainFGColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _buildCircleIconButton(context, Icons.share, () {
          // Add share functionality
        }),
      ],
    );
  }

  Widget _buildCircleIconButton(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mainFGColor, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.mainFGColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDescriptionCard(Challenge challenge) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
            maxWidth: 400,
            minHeight: 120), // Adjust minHeight for desired 4-line space
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "\"${challenge.challengeDescription}\"",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                    color: AppColors.mainFGColor,
                    height: 1.5, // Line height for readability
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 10, // Limit the number of lines if needed
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Weight Info Section Builder with Cards
  Widget _buildWeightInfo({
    required double? currentWeight,
    required double? startingWeight,
    required double? goalWeight,
    required String weightUnit,
    required int daysLeft,
    required ChallengeType challengeType,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChallengeInfoCard(
              title: "Current Weight",
              value: currentWeight != null
                  ? "${currentWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
            const SizedBox(width: 8),
            _ChallengeInfoCard(
              title: "Starting Weight",
              value: startingWeight != null
                  ? "${startingWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChallengeInfoCard(
              title: "Goal Weight",
              value: goalWeight != null
                  ? "${goalWeight.toStringAsFixed(1)} $weightUnit"
                  : "N/A",
            ),
            const SizedBox(width: 8),
            _ChallengeInfoCard(
              title: "Days Left",
              value: "$daysLeft",
            ),
          ],
        ),
      ],
    );
  }
}

// Custom widget for displaying challenge information in a card format
class _ChallengeInfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _ChallengeInfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  color: AppColors.mainFGColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mainFGColor,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
