import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../services/firebase_analytics_service.dart';
import '../services/user_service.dart';
import '../widgets/active_challenges_section.dart';
import '../widgets/available_challenges_section.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../models/user_profile.dart';
import 'profile_page.dart';
import 'leaderboard_screen.dart';
import 'side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

final UserService _userService = UserService();

class _MainScreenState extends State<MainScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    analyticsService.logCustomEvent(
      screenName: 'main_screen',
      action: 'open',
    );
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

  String calculateDaysAgo(int userJoinDate) {
    final joinDate = DateTime.fromMillisecondsSinceEpoch(userJoinDate);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(joinDate).inDays;
    return "${difference}D";
  }

  void _openProfileScreen(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final challengeProvider =
        Provider.of<ChallengeProvider>(context, listen: false);
    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    analyticsService.logCustomEvent(
      screenName: 'profile_page_screen',
      action: 'open',
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Using FutureBuilder to wait for async data
        return FutureBuilder<UserProfile?>(
          future: authService.getCurrentUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while waiting for data
              return const Center(
                  child: LoadingOverlay(
                opacity: 55,
              ));
            }

            if (snapshot.hasError) {
              // Handle error, if any
              return AlertDialog(
                title: const Text("Error"),
                content: const Text("Failed to load user profile."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              );
            }

            // Extract user profile data or use defaults if null
            final UserProfile? userProfile = snapshot.data;
            final int peopleInvitedCount = userProfile?.userInvited ?? 0;
            final String name =
                authService.currentUser?.displayName ?? "Unknown User";
            final String? profilePictureUrl = authService.currentUser?.photoURL;
            final int challengesCount =
                challengeProvider.activeChallenges.length;
            final int wonCount = 0;
            final String joinedDate =
                calculateDaysAgo(userProfile!.userJoinDate);

            return ProfilePage(
              name: name,
              profilePictureUrl: profilePictureUrl,
              challengesCount: challengesCount,
              wonCount: wonCount,
              peopleInvitedCount: peopleInvitedCount,
              joinedDate: joinedDate,
            );
          },
        );
      },
    );
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
      backgroundColor: Colors.white,
      drawer: SideMenu(
        userName: user?.displayName ?? "Guest",
        profilePictureUrl: user?.photoURL,
        tagline: "Challenge yourself, achieve greatness!",
      ),
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
                        // Profile Picture with GestureDetector to open Profile Screen as modal
                        GestureDetector(
                          onTap: () => _openProfileScreen(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, size: 30)
                                : null, // Placeholder icon
                          ),
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

                        const SizedBox(width: 40),
                        // Menu Icon
                        // Padding(
                        //   padding: const EdgeInsets.only(right: 0.0),
                        //   child: Builder(
                        //     builder: (BuildContext context) {
                        //       return GestureDetector(
                        //         onTap: () => Scaffold.of(context).openDrawer(),
                        //         child: const Icon(
                        //           Icons.menu,
                        //           size: 40,
                        //           color: Color(0xFF083400),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaderboardScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFFf7f2fa), // Light green button color
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(25), // Rounded edges
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ), // Larger padding for a more prominent look
                            elevation: 5, // Subtle shadow for depth
                          ),
                          icon: const Icon(
                            Icons.emoji_events, // Trophy icon
                            color: Color(0xFF083400), // Dark green for contrast
                            size: 20,
                          ),
                          label: const Text(
                            "Today's Winners",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF083400), // Dark green text color
                            ),
                          ),
                        ),
                      ],
                    ),

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
