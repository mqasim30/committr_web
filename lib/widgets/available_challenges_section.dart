import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';
import '../services/server_time_service.dart';
import '../services/log_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvailableChallengesSection extends StatefulWidget {
  final List<Challenge> availableChallenges;

  const AvailableChallengesSection(
      {super.key, required this.availableChallenges});

  @override
  _AvailableChallengesSectionState createState() =>
      _AvailableChallengesSectionState();
}

class _AvailableChallengesSectionState
    extends State<AvailableChallengesSection> {
  late Timer timer;
  Map<String, Duration> countdownTimers = {};
  bool countdownInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCountdowns();
  }

  Future<void> _initializeCountdowns() async {
    DateTime serverTime = await ServerTimeService.getServerTime();
    LogService.info(serverTime.toIso8601String());

    for (var challenge in widget.availableChallenges) {
      DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
          challenge.challengeStartTimestamp);
      LogService.info("Challenge start time: ${startTime.toIso8601String()}");

      Duration timeRemaining = startTime.difference(serverTime);
      LogService.info("Time remaining: ${timeRemaining.inSeconds} seconds");

      countdownTimers[challenge.challengeId] =
          timeRemaining.isNegative ? Duration.zero : timeRemaining;
    }

    setState(() {
      countdownInitialized = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _updateCountdowns();
      });
    });
  }

  void _updateCountdowns() {
    countdownTimers.updateAll((id, timeRemaining) {
      return timeRemaining > Duration.zero
          ? timeRemaining - const Duration(seconds: 1)
          : Duration.zero;
    });
  }

  String _formatTimeSpan(Duration duration) {
    if (duration == Duration.zero) {
      return "Challenge Started!";
    }
    return "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick Your Commitment:',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.mainFGColor,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;

            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth >= 800) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5, // Adjusted to make the card taller
              ),
              itemCount: widget.availableChallenges.length,
              itemBuilder: (context, index) {
                Challenge challenge = widget.availableChallenges[index];
                String countdownText = countdownInitialized
                    ? _formatTimeSpan(
                        countdownTimers[challenge.challengeId] ?? Duration.zero)
                    : "Loading...";

                // Determine the appropriate text to display
                String displayText = countdownText == "Challenge Started!" ||
                        countdownText == "Loading..."
                    ? countdownText
                    : "Starting in: $countdownText";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeDetailScreen(
                          challenge: challenge,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double cardHeight = constraints.maxHeight;

                        // Define font sizes based on card height
                        double titleFontSize = cardHeight * 0.09;
                        double subTitleFontSize = cardHeight * 0.08;
                        double smallFontSize = cardHeight * 0.07;
                        double bottomFontSize = cardHeight * 0.07;

                        // Ensure font sizes are within reasonable bounds
                        titleFontSize = titleFontSize.clamp(14.0, 22.0);
                        subTitleFontSize = subTitleFontSize.clamp(12.0, 18.0);
                        smallFontSize = smallFontSize.clamp(10.0, 16.0);
                        bottomFontSize = bottomFontSize.clamp(10.0, 16.0);

                        return Column(
                          children: [
                            // Top Header with Title and Button
                            Container(
                              height: cardHeight * 0.25, // 25% of card height
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        challenge.challengeTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: titleFontSize,
                                          color: AppColors.mainFGColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.mainBgColor,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.arrow_outward,
                                      color: AppColors.mainFGColor,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Middle Section
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${challenge.challengeNumberParticipants}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: subTitleFontSize,
                                          color: AppColors.mainFGColor,
                                        ),
                                      ),
                                      Text(
                                        'Participants',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: smallFontSize,
                                          color: AppColors.mainFGColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  VerticalDivider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    width: 0,
                                    indent: 27.5, // Adds space at the top
                                    endIndent: 27.5, // Adds space at the bottom
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '\$${challenge.challengePotSize}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: subTitleFontSize,
                                          color: AppColors.mainFGColor,
                                        ),
                                      ),
                                      Text(
                                        'Pot Size',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: smallFontSize,
                                          color: AppColors.mainFGColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Section with Profile Pictures and Countdown
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Profile Pictures Row
                                  SizedBox(
                                    height:
                                        cardHeight * 0.25, // Adjust as needed
                                    child: _buildProfilePicturesRow(
                                        challenge.participantsProfilePictureUrl,
                                        challenge.challengeNumberParticipants),
                                  ),
                                  const SizedBox(height: 4),
                                  // "Members participated today" Text
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      'members participated today',
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                        fontSize: smallFontSize,
                                        color: AppColors.mainFGColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Countdown Text
                                  Text(
                                    displayText,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: bottomFontSize,
                                      color: AppColors.mainFGColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
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
                    color: Colors.white.withOpacity(0.5),
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
}
