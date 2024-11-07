// lib/screens/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:provider/provider.dart';
import '../constants/challenge_constants.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../services/auth_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/step_card.dart';
import '../widgets/user_challenge_info_card.dart';
import '../widgets/rules_card.dart';
import 'pledge_amount_selection_screen.dart';
import '../constants/constants.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  _ChallengeDetailScreenState createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  /// Navigates to the Pledge Amount Selection Screen.
  void navigateToPledgeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PledgeAmountSelectionScreen(challenge: widget.challenge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final updatedChallenge = challengeProvider.activeChallenges.firstWhere(
        (c) => c.challengeId == widget.challenge.challengeId,
        orElse: () => widget.challenge);

    final userChallengeDetail =
        challengeProvider.userChallenges[widget.challenge.challengeId];

    final String detailedDescription =
        ChallengeConstants.getDetailedDescription(
            updatedChallenge.challengeTitle);

    // Convert timestamps to DateTime and format
    final DateTime startDate = DateTime.fromMillisecondsSinceEpoch(
        updatedChallenge.challengeStartTimestamp);
    final DateTime endDate = DateTime.fromMillisecondsSinceEpoch(
        updatedChallenge.challengeEndTimestamp);

    final String formattedStartDate =
        DateFormat('MMMM dd, yyyy').format(startDate);
    final String formattedEndDate = DateFormat('MMMM dd, yyyy').format(endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (isLoading) const LoadingOverlay(),
          if (!isLoading)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Outlined Circle for Back Icon
                      Container(
                        padding: const EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.mainFGColor, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.mainFGColor),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      // Title
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
                                  height: 1.2),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              updatedChallenge.challengeTitle,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: AppColors.mainFGColor,
                                  height: 1.2),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Centered Card with Max Width Constraint and Increased Height
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Title
                              Text(
                                "\"${updatedChallenge.challengeDescription}\"",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Poppins',
                                  color: AppColors.mainFGColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Participants and Pot Size with Divider
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "${updatedChallenge.challengeNumberParticipants}",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'Poppins',
                                              color: AppColors.mainFGColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Participants",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: AppColors.mainFGColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Centered Divider
                                    Container(
                                      height: 50,
                                      width: 1,
                                      color: Colors.grey,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "\$${updatedChallenge.challengePotSize}",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'Poppins',
                                              color: AppColors.mainFGColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Pot Size",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: AppColors.mainFGColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Members Committed Today Text
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                child: Text(
                                  "${updatedChallenge.challengeNumberParticipants}+ members joined today",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Poppins',
                                    color: AppColors.mainFGColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Start and End Dates
                              Column(
                                children: [
                                  Text(
                                    'Start Date: $formattedStartDate',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                      color: AppColors.mainFGColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'End Date: $formattedEndDate',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                      color: AppColors.mainFGColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Steps Section
                  const Text('Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          color: AppColors.mainFGColor)),
                  const SizedBox(height: 10),
                  StepCard(
                      text: "Pledge: Deposit \$35 to keep you accountable."),
                  StepCard(text: "Commit: $detailedDescription"),
                  StepCard(
                      text: "Success: Get your deposited amount plus extra."),

                  const SizedBox(height: 20),

                  // Rules Section
                  const Text('Rules:',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          color: AppColors.mainFGColor)),
                  const SizedBox(height: 10),

                  // Rule Cards with Bottom Padding
                  ...updatedChallenge.rules.asMap().entries.map(
                        (entry) => RulesCard(
                          ruleText: entry.value,
                          ruleIndex: entry.key,
                        ),
                      ),
                  const SizedBox(height: 80), // Extra padding for scroll

                  // User Challenge Info Section
                  if (userChallengeDetail != null)
                    UserChallengeInfoCard(
                      userChallengeDetail: userChallengeDetail,
                      challengeId: updatedChallenge.challengeId,
                      authService: authService,
                    ),
                ],
              ),
            ),

          // Floating Continue Button with Outer Rectangle and Centered Button
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFFEDEFEB), // Outer rectangle color
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: SizedBox(
                width: 250, // Desired width
                height: 40, // Desired height
                child: ElevatedButton(
                  onPressed: userChallengeDetail == null
                      ? navigateToPledgeSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainFGColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
