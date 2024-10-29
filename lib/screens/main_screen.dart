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
      await challengeProvider.initialize();
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
              radius: 20,
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
                  ? const Icon(Icons.person, size: 30)
                  : null, // Placeholder icon
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Color(0xFF083400),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: Offset(-5, 0),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                challengeProvider.activeChallenges.length,
                            itemBuilder: (context, index) {
                              Challenge challenge =
                                  challengeProvider.activeChallenges[index];
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
                                      switch (userChallengeDetail
                                          .userChallengeStatus) {
                                        case 'In Progress':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChallengeProgressScreen(
                                                challenge: challenge,
                                              ),
                                            ),
                                          );
                                          break;
                                        case 'Submission':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SubmissionScreen(
                                                userId:
                                                    Provider.of<AuthService>(
                                                            context,
                                                            listen: false)
                                                        .currentUser!
                                                        .uid,
                                                challengeId:
                                                    challenge.challengeId,
                                              ),
                                            ),
                                          );
                                          break;
                                        case 'Pending':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PendingScreen(
                                                challenge: challenge,
                                              ),
                                            ),
                                          );
                                          break;
                                        case 'Missed Submission':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MissedSubmissionScreen(
                                                challenge: challenge,
                                              ),
                                            ),
                                          );
                                          break;
                                        case 'Completed':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CompletedScreen(
                                                challenge: challenge,
                                              ),
                                            ),
                                          );
                                          break;
                                        case 'Failed':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FailedScreen(
                                                challenge: challenge,
                                              ),
                                            ),
                                          );
                                          break;
                                        default:
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
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
                                  //color: Color(0xFFEDEFEB),
                                  elevation: 4,
                                  margin: const EdgeInsets.only(
                                      right: 10, bottom: 10, left: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                    width: 180, // Fixed width for each card
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top header with Title and Circular Button
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 8,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 0),
                                                child: Text(
                                                  challenge.challengeTitle,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 15),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF9FE870),
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(
                                                    5), // Reduced padding for a more compact button
                                                child: const Icon(
                                                  Icons.arrow_outward,
                                                  color: Color(0xFF083400),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        // Body with Pledge Text
                                        Text(
                                          '\$${userChallengeDetail?.userChallengePledgeAmount ?? '0'} Pledged',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Color(0xFF083400),
                                          ),
                                        ),
                                        Spacer(), // Spacer to manage flexible height
                                        // Footer with Progress Bar
                                        Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            child: LinearProgressIndicator(
                                              value:
                                                  0.5, // Sample progress value
                                              backgroundColor: Colors.grey[300],
                                              color: const Color(0xFF9FE870),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Available Challenges (Responsive Grid with Fixed Height)
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.8,
                          ),
                          itemCount:
                              challengeProvider.availableChallenges.length,
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
                              child: SizedBox(
                                height: 250,
                                child: Card(
                                  //color: Color(0xFFEDEFEB),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      // Top Header with Title and Button
                                      Container(
                                        height: 0.25 * 250,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left:
                                                        8), // Added left padding
                                                child: Text(
                                                  challenge.challengeTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 18,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9FE870),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${challenge.challengeNumberParticipants}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 18,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                                const Text(
                                                  'Participants',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              height: 40,
                                              width: 1,
                                              color: Colors.grey,
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '\$${challenge.challengePotSize}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 18,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                                const Text(
                                                  'Pot Size',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                    color: Color(0xFF083400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bottom Header
                                      Container(
                                        height: 0.25 * 250,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '100 members participated today',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14,
                                                color: Color(0xFF083400),
                                              ),
                                            ),
                                            Text(
                                              'Starting in: 02:05',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14,
                                                color: Color(0xFF083400),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}
