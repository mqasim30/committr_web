// lib/screens/challenge_progress_screen.dart

import 'package:Committr/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/constants.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../services/server_time_service.dart';
import '../utils/challenge_helper.dart';
import '../services/log_service.dart';
import '../widgets/rules_card.dart';
import '../widgets/custom_progress_bar.dart';
import '../services/auth_service.dart';
import '../widgets/weight_challenge_progress_widget.dart';
import '../widgets/reduce_screen_time_progress_widget.dart';
import '../widgets/wake_up_early_progress_widget.dart';

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;
  final double pledgedAmount;

  const ChallengeProgressScreen(
      {super.key, required this.challenge, required this.pledgedAmount});

  @override
  _ChallengeProgressScreenState createState() =>
      _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  DateTime? _currentDate;
  late ChallengeType _challengeType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _challengeType =
        ChallengeHelper.getChallengeType(widget.challenge.challengeTitle);
    _fetchServerTime();
  }

  /// Fetches the current server time using ServerTimeService
  Future<void> _fetchServerTime() async {
    try {
      DateTime serverTime = await ServerTimeService.getServerTime();
      setState(() {
        _currentDate = serverTime;
        _isLoading = false;
      });
    } catch (e) {
      LogService.error("Error fetching server time: $e");
      setState(() {
        _isLoading = false;
      });
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch server time.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userChallengeDetail =
        challengeProvider.userChallenges[widget.challenge.challengeId];

    if (_isLoading || userChallengeDetail == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: LoadingOverlay(),
        ),
      );
    }

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
            // Build Challenge Specific UI
            _buildChallengeSpecificUI(userChallengeDetail, authService),
            const SizedBox(height: 20),
            // Challenge Progress Bar
            _buildProgressBar(),
            const SizedBox(height: 20),
            // Rules Section
            _buildRulesSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the custom header with back and share buttons
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
              const Text(
                'Challenge:',
                style: TextStyle(
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
        const SizedBox(
          width: 40,
        )
      ],
    );
  }

  /// Builds a circular icon button with border
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

  /// Builds the challenge description card
  Widget _buildDescriptionCard(Challenge challenge) {
    final startDate = DateFormat('dd MMM yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeStartTimestamp));
    final endDate = DateFormat('dd MMM yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeEndTimestamp));

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, minHeight: 120),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Challenge Title
                Text(
                  "\"${challenge.challengeDescription}\"",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                    color: AppColors.mainFGColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Pledged, Participants, Pot Size Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "\$${widget.pledgedAmount}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pledged',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "${challenge.challengeNumberParticipants}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Participants',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "\$${challenge.challengePotSize}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pot Size',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Start and End Dates with Divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            startDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            endDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ending',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mainFGColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the challenge-specific widget based on the challenge type
  Widget _buildChallengeSpecificUI(
      UserChallengeDetail userChallengeDetail, AuthService authService) {
    switch (_challengeType) {
      case ChallengeType.Lose4Percent:
      case ChallengeType.Lose10Percent:
      case ChallengeType.MaintainWeight:
        return WeightChallengeProgressWidget(
          challenge: widget.challenge,
          userChallengeDetail: userChallengeDetail,
          currentDate: _currentDate!,
        );
      case ChallengeType.ReduceScreenTime:
        return ReduceScreenTimeProgressWidget(
          challenge: widget.challenge,
          userChallengeDetail: userChallengeDetail,
          currentDate: _currentDate!,
        );
      case ChallengeType.WakeUpEarly:
        return WakeUpEarlyProgressWidget(
          challenge: widget.challenge,
          userChallengeDetail: userChallengeDetail,
          authService: authService,
          currentDate: _currentDate!,
        );
      default:
        return const Center(
          child: Text(
            'Challenge type not supported.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: AppColors.mainFGColor,
            ),
          ),
        );
    }
  }

  /// Builds the progress bar section
  Widget _buildProgressBar() {
    final startDate = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeStartTimestamp);
    final endDate = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeEndTimestamp);
    final currentDate = _currentDate!;
    final progress =
        ChallengeHelper.calculateProgress(startDate, endDate, currentDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress:',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.mainFGColor),
        ),
        const SizedBox(height: 10),
        CustomProgressBar(progress: progress), // Custom progress widget
      ],
    );
  }

  /// Builds the rules section of the challenge
  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
