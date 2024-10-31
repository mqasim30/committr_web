import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../widgets/active_challenges_section.dart';
import '../widgets/available_challenges_section.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';

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

  /// Determines greeting based on local time
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    // Determine if we have active or available challenges to show
    final hasActiveChallenges = challengeProvider.activeChallenges.isNotEmpty;
    final hasAvailableChallenges =
        challengeProvider.availableChallenges.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: fetchData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Profile, Username, Greeting, and Menu Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 30)
                              : null, // Placeholder icon
                        ),
                        // User Greeting Section
                        Padding(
                          padding: const EdgeInsets.only(top: 7.5),
                          child: Column(
                            children: [
                              Text(
                                user != null
                                    ? 'Hello, ${user.displayName}'
                                    : 'Hello',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  color: Color(0xFF083400),
                                ),
                              ),
                              Text(
                                getGreeting(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Color(0xFF083400),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Menu Icon
                        Padding(
                          padding: const EdgeInsets.only(right: 0.0),
                          child: GestureDetector(
                            onTap: () {
                              // Open the menu or navigation drawer
                            },
                            child: const Icon(
                              Icons.menu,
                              size: 40,
                              color: Color(0xFF083400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // // Row with Leaderboard and Invite buttons
                    // Row(
                    //   children: [
                    //     // Leaderboard button with 65% width
                    //     Expanded(
                    //       flex: 65,
                    //       child: ElevatedButton.icon(
                    //         onPressed: () {
                    //           // Navigate to Leaderboard screen
                    //         },
                    //         icon: const Icon(Icons.emoji_events_outlined,
                    //             color: Color(0xFF083400), size: 20),
                    //         label: const Text(
                    //           'Leaderboard',
                    //           style: TextStyle(
                    //             fontFamily: 'Poppins',
                    //             fontWeight: FontWeight.w400,
                    //             fontSize: 16,
                    //             color: Color(0xFF083400),
                    //           ),
                    //         ),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Color(0xfff7f2fa),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(15),
                    //           ),
                    //           elevation: 4, // Add elevation for shadow
                    //           shadowColor: Colors.grey.withOpacity(0.5),
                    //           padding: const EdgeInsets.symmetric(vertical: 15),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 10),

                    //     // Invite button with 35% width
                    //     Expanded(
                    //       flex: 35,
                    //       child: ElevatedButton.icon(
                    //         onPressed: () {
                    //           // Navigate to Invite screen or share functionality
                    //         },
                    //         icon: const Icon(Icons.favorite_border,
                    //             color: Color(0xFF083400), size: 20),
                    //         label: const Text(
                    //           'Invite',
                    //           style: TextStyle(
                    //             fontFamily: 'Poppins',
                    //             fontWeight: FontWeight.w400,
                    //             fontSize: 16,
                    //             color: Color(0xFF083400),
                    //           ),
                    //         ),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Color(0xfff7f2fa),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(15),
                    //           ),
                    //           elevation: 4, // Add elevation for shadow
                    //           shadowColor: Colors.grey.withOpacity(0.5),
                    //           padding: const EdgeInsets.symmetric(vertical: 15),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    const SizedBox(height: 20),

                    // Active Commitments Section (shown only if there are active challenges)
                    if (hasActiveChallenges) ...[
                      const ActiveChallengesSection(),
                      const SizedBox(height: 30),
                    ],

                    // Available Challenges Section (shown only if there are available challenges)
                    if (hasAvailableChallenges)
                      AvailableChallengesSection(
                        availableChallenges:
                            challengeProvider.availableChallenges,
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
