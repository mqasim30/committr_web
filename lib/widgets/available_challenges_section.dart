import 'dart:async';
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';
import '../services/server_time_service.dart';
import '../services/log_service.dart';

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
            color: Color(0xFF083400),
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
                childAspectRatio: 1.7,
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
                        double titleFontSize = cardHeight * 0.1;
                        double subTitleFontSize = cardHeight * 0.1;
                        double smallFontSize = cardHeight * 0.08;
                        double bottomFontSize = cardHeight * 0.07;

                        // Ensure font sizes are within reasonable bounds
                        titleFontSize = titleFontSize.clamp(16.0, 24.0);
                        subTitleFontSize = subTitleFontSize.clamp(14.0, 20.0);
                        smallFontSize = smallFontSize.clamp(12.0, 16.0);
                        bottomFontSize = bottomFontSize.clamp(12.0, 16.0);

                        return Column(
                          children: [
                            // Top Header with Title and Button
                            Container(
                              height: cardHeight * 0.25, // 20% of card height
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
                                          color: const Color(0xFF083400),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF9FE870),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.arrow_outward,
                                      color: Color(0xFF083400),
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
                                          color: const Color(0xFF083400),
                                        ),
                                      ),
                                      Text(
                                        'Participants',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: smallFontSize,
                                          color: const Color(0xFF083400),
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
                                          color: const Color(0xFF083400),
                                        ),
                                      ),
                                      Text(
                                        'Pot Size',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: smallFontSize,
                                          color: const Color(0xFF083400),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Header with Countdown Timer
                            SizedBox(
                              height: cardHeight * 0.25, // 25% of card height
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${challenge.challengeNumberParticipants} members participated today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: smallFontSize,
                                      color: const Color(0xFF083400),
                                    ),
                                  ),
                                  Text(
                                    displayText,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: bottomFontSize,
                                      color: const Color(0xFF083400),
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
}
