// lib/screens/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/challenge_constants.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_analytics_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/step_card.dart';
import '../widgets/user_challenge_info_card.dart';
import '../widgets/rules_card.dart';
import 'pledge_amount_selection_screen.dart';
import '../constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    analyticsService.logCustomEvent(
      screenName: 'challenge_detail_screen',
      action: 'open',
    );
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

  // Helper method to build the profile pictures row
  Widget _buildProfilePicturesRow(List<String> urls, int totalParticipants) {
    // Limit to 4 URLs for profile pictures
    List<String> displayUrls = urls.take(4).toList();

    double circleRadius = 20.0;
    double overlap = circleRadius * 1.1;

    // Calculate total number of circles
    int totalCircles = displayUrls.length;
    bool showExtraCircle = totalParticipants > displayUrls.length;
    if (showExtraCircle) {
      totalCircles += 1;
    }

    double totalWidth = circleRadius * 2 + (totalCircles - 1) * overlap;

    return Center(
      child: SizedBox(
        width: totalWidth,
        height: circleRadius * 2,
        child: Stack(
          children: [
            // Profile Picture Circles
            for (int index = 0; index < displayUrls.length; index++)
              Positioned(
                left: index * overlap,
                child: Container(
                  width: circleRadius * 2,
                  height: circleRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mainFGColor),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          "${displayUrls[index]}?timestamp=${DateTime.now().millisecondsSinceEpoch ~/ (60 * 60 * 1000)}",
                      // Add a timestamp that changes every hour
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person, color: AppColors.mainFGColor),
                      ),
                    ),
                  ),
                ),
              ),
            // Extra Circle with Participant Count
            if (showExtraCircle)
              Positioned(
                left: displayUrls.length * overlap,
                child: Container(
                  width: circleRadius * 2,
                  height: circleRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                        .withOpacity(0.7), // Semi-transparent background
                    border: Border.all(color: AppColors.mainFGColor),
                  ),
                  child: Center(
                    child: Text(
                      '+${totalParticipants - displayUrls.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: circleRadius * 0.7,
                        color: AppColors.mainFGColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        DateFormat('dd MMM yyyy').format(startDate);
    final String formattedEndDate = DateFormat('dd MMM yyyy').format(endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (isLoading) const LoadingOverlay(),
          if (!isLoading)
            SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Outlined Circle for Back Icon
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.mainFGColor,
                            width: 2,
                          ),
                        ),
                        width: 30.0, // Desired width for the outer circle
                        height: 30.0, // Desired height for the outer circle
                        child: Center(
                          // Use Center instead of Align
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: AppColors.mainFGColor),
                            iconSize: 17.5,
                            padding: EdgeInsets.zero, // Remove default padding
                            constraints:
                                const BoxConstraints(), // Remove additional constraints
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),

                      // Title
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center vertically
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
                              updatedChallenge.challengeTitle,
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

                      const SizedBox(width: 40),
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
                              const SizedBox(height: 16),

                              // Start and End Dates with Divider
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          formattedStartDate,
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          formattedEndDate,
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
                              const SizedBox(height: 16),

                              // Profile Pictures Row
                              _buildProfilePicturesRow(
                                updatedChallenge.participantsProfilePictureUrl,
                                updatedChallenge.challengeNumberParticipants,
                              ),
                              const SizedBox(height: 8),

                              // Members Committed Today Text
                              Text(
                                "members joined today",
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
