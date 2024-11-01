import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../providers/challenge_provider.dart';
import '../services/auth_service.dart';
import '../services/server_time_service.dart';
import '../screens/oath_screen.dart';
import '../screens/challenge_progress_screen.dart';
import '../screens/submission_screen.dart';
import '../screens/missed_submission_screen.dart';
import '../screens/pending_screen.dart';
import '../screens/completed_screen.dart';
import '../screens/failed_screen.dart';

class ActiveChallengesSection extends StatelessWidget {
  const ActiveChallengesSection({super.key});

  /// Helper function to split the title into two lines.
  /// Places the first word on the first line and the rest on the second line.
  String splitTitle(String title) {
    List<String> words = title.split(' ');
    if (words.length <= 1) {
      return title;
    } else {
      String firstLine = words[0];
      String secondLine = words.sublist(1).join(' ');
      return '$firstLine\n$secondLine';
    }
  }

  Future<double> calculateProgress(Challenge challenge) async {
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeStartTimestamp);
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeEndTimestamp);
    final currentTime = await ServerTimeService.getServerTime();

    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsedTime = currentTime.difference(startTime).inSeconds;

    if (elapsedTime <= 0) return 0.0;
    if (elapsedTime >= totalDuration) return 1.0;
    return elapsedTime / totalDuration;
  }

  Future<String> getTimeLeft(Challenge challenge) async {
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(challenge.challengeEndTimestamp);
    final currentTime = await ServerTimeService.getServerTime();

    Duration timeLeft = endTime.difference(currentTime);
    if (timeLeft.isNegative) {
      return "Challenge Ended";
    } else if (timeLeft.inDays > 0) {
      return "Time Left: ${timeLeft.inDays} days, ${(timeLeft.inHours % 24)} hrs";
    } else {
      return "Time Left: ${timeLeft.inHours} hrs, ${(timeLeft.inMinutes % 60)} mins";
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final userChallenges = challengeProvider.userChallenges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Commitments:',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF083400),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160, // Adjusted height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: challengeProvider.activeChallenges.length,
            itemBuilder: (context, index) {
              Challenge challenge = challengeProvider.activeChallenges[index];
              UserChallengeDetail? userChallengeDetail =
                  userChallenges[challenge.challengeId];

              return GestureDetector(
                onTap: () {
                  if (userChallengeDetail != null) {
                    if (!userChallengeDetail.isOathTaken) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OathScreen(
                            userId:
                                Provider.of<AuthService>(context, listen: false)
                                    .currentUser!
                                    .uid,
                            challengeId: challenge.challengeId,
                          ),
                        ),
                      );
                    } else {
                      switch (userChallengeDetail.userChallengeStatus) {
                        case 'In Progress':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChallengeProgressScreen(challenge: challenge),
                            ),
                          );
                          break;
                        case 'Submission':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubmissionScreen(
                                userId: Provider.of<AuthService>(context,
                                        listen: false)
                                    .currentUser!
                                    .uid,
                                challengeId: challenge.challengeId,
                              ),
                            ),
                          );
                          break;
                        case 'Pending':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PendingScreen(challenge: challenge),
                            ),
                          );
                          break;
                        case 'Missed Submission':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MissedSubmissionScreen(challenge: challenge),
                            ),
                          );
                          break;
                        case 'Completed':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CompletedScreen(challenge: challenge),
                            ),
                          );
                          break;
                        case 'Failed':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FailedScreen(challenge: challenge),
                            ),
                          );
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Unknown status: ${userChallengeDetail.userChallengeStatus}'),
                            ),
                          );
                      }
                    }
                  }
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(right: 10, bottom: 10, left: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 5,
                        bottom: 10), // Reduced top padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section with Title and Action Button
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align to top
                          children: [
                            Expanded(
                              child: Text(
                                splitTitle(challenge.challengeTitle),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF083400),
                                ),
                              ),
                            ),
                            // Adjusted circular button positioning
                            Transform.translate(
                              offset: const Offset(0, 5), // Move up by 5 pixels
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9FE870),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(5),
                                child: const Icon(
                                  Icons.arrow_outward,
                                  color: Color(0xFF083400),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.5),

                        // Pledge Amount
                        Text(
                          '\$${userChallengeDetail?.userChallengePledgeAmount ?? '0'} Pledged',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF083400),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Time Left
                        FutureBuilder<String>(
                          future: getTimeLeft(challenge),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? "Calculating...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Color(0xFF083400),
                              ),
                            );
                          },
                        ),
                        const Spacer(),

                        // Footer with Progress Bar and Text
                        FutureBuilder<double>(
                          future: calculateProgress(challenge),
                          builder: (context, snapshot) {
                            double progress = snapshot.data ?? 0.0;
                            String progressText =
                                "${(progress * 100).round()}% Done";

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 20,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[300],
                                      color: const Color(0xFF9FE870),
                                    ),
                                  ),
                                ),
                                Text(
                                  progressText,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF083400),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
