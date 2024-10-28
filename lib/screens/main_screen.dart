// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import 'challenge_detail_screen.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import 'oath_screen.dart';
import 'challenge_progress_screen.dart';
import 'submission_screen.dart';
import 'missed_submission_screen.dart';
import 'pending_screen.dart';
import 'completed_screen.dart';
import 'failed_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// Fetches challenges and updates the loading state accordingly.
  Future<void> fetchData() async {
    try {
      final challengeProvider =
          Provider.of<ChallengeProvider>(context, listen: false);
      await challengeProvider
          .initialize(); // Initialize with real-time listeners
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      LogService.error('Error fetching challenges: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching challenges: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final userChallenges = challengeProvider.userChallenges;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20, // Adjust the radius as needed
              backgroundImage: Provider.of<AuthService>(context, listen: false)
                          .currentUser!
                          .photoURL !=
                      null
                  ? NetworkImage(
                      Provider.of<AuthService>(context, listen: false)
                          .currentUser!
                          .photoURL!)
                  : null,
              child: Provider.of<AuthService>(context, listen: false)
                          .currentUser!
                          .photoURL ==
                      null
                  ? const Icon(Icons.person, size: 30) // Placeholder icon
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
                'Hello, ${Provider.of<AuthService>(context, listen: false).currentUser!.displayName}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Open the menu or navigation drawer
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content with RefreshIndicator
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                isLoading = true;
              });
              await fetchData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Static Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Leaderboard
                          },
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('Leaderboard'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Invite action
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('Invite'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Commitments (Horizontal Scroll)
                    const Text(
                      'Active Commitments:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150, // Set a fixed height for active challenges
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: challengeProvider.activeChallenges.length,
                        itemBuilder: (context, index) {
                          Challenge challenge =
                              challengeProvider.activeChallenges[index];
                          UserChallengeDetail? userChallengeDetail =
                              userChallenges[challenge.challengeId];

                          return GestureDetector(
                            onTap: () {
                              // Handle based on userChallengeStatus
                              if (userChallengeDetail != null) {
                                if (!userChallengeDetail.isOathTaken) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OathScreen(
                                        userId: Provider.of<AuthService>(
                                                context,
                                                listen: false)
                                            .currentUser!
                                            .uid,
                                        challengeId: challenge.challengeId,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Determine navigation based on the user challenge status
                                  switch (
                                      userChallengeDetail.userChallengeStatus) {
                                    case 'In Progress':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChallengeProgressScreen(
                                                  challenge: challenge),
                                        ),
                                      );
                                      break;
                                    case 'Submission':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubmissionScreen(
                                            userId: Provider.of<AuthService>(
                                                    context,
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
                                          builder: (context) => PendingScreen(
                                              challenge: challenge),
                                        ),
                                      );
                                      break;
                                    case 'Missed Submission':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MissedSubmissionScreen(
                                                  challenge: challenge),
                                        ),
                                      );
                                      break;
                                    case 'Completed':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CompletedScreen(
                                              challenge: challenge),
                                        ),
                                      );
                                      break;
                                    case 'Failed':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FailedScreen(
                                              challenge: challenge),
                                        ),
                                      );
                                      break;
                                    default:
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Unknown status: ${userChallengeDetail.userChallengeStatus}')),
                                      );
                                  }
                                }
                              }
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.challengeTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      '\$${userChallengeDetail?.userChallengePledgeAmount ?? '0'} Pledged'),
                                  const Spacer(),
                                  LinearProgressIndicator(
                                    value:
                                        0.5, // Replace with actual progress value
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Available Challenges (Vertical Scroll)
                    const Text(
                      'Pick Your Commitment:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: challengeProvider.availableChallenges.length,
                      itemBuilder: (context, index) {
                        Challenge challenge =
                            challengeProvider.availableChallenges[index];
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
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.challengeTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    '${challenge.challengeNumberParticipants} Participants'),
                                const SizedBox(height: 8),
                                Text(
                                    'Pot Size: \$${challenge.challengePotSize}'),
                                const SizedBox(height: 8),
                                const Text('100 members participated today'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Loading Overlay
          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}
