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
import 'login_screen.dart';
import 'oath_screen.dart'; // Import OathScreen
// Import for kIsWeb if needed

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
      // Optionally, show an error message to the user
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
        title: const Text('Main Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                isLoading = true;
              });
              await fetchData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Available Challenges',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  challengeProvider.availableChallenges.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              challengeProvider.availableChallenges.length,
                          itemBuilder: (context, index) {
                            Challenge challenge =
                                challengeProvider.availableChallenges[index];
                            return ListTile(
                              title: Text(challenge.challengeTitle),
                              subtitle: Text(
                                  'Duration: ${challenge.challengeDurationDays} days\nCategory: ${challenge.challengeCategory}'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChallengeDetailScreen(
                                        challenge: challenge,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Join'),
                              ),
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
                            );
                          },
                        )
                      : const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No available challenges at the moment.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 40),
                  const Text(
                    'Active Challenges',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  challengeProvider.activeChallenges.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: challengeProvider.activeChallenges.length,
                          itemBuilder: (context, index) {
                            Challenge challenge =
                                challengeProvider.activeChallenges[index];
                            UserChallengeDetail? userChallengeDetail =
                                userChallenges[challenge.challengeId];
                            return ListTile(
                              title: Text(challenge.challengeTitle),
                              subtitle: Text(
                                  'Duration: ${challenge.challengeDurationDays} days\nPot Size: \$${challenge.challengePotSize}\nParticipants: ${challenge.challengeNumberParticipants}'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  if (userChallengeDetail != null &&
                                      !userChallengeDetail.isOathTaken) {
                                    // Navigate to Oath Screen
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
                                    // Navigate to Challenge Detail Screen without passing userChallengeDetail
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChallengeDetailScreen(
                                          challenge: challenge,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('View'),
                              ),
                            );
                          },
                        )
                      : const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No active challenges at the moment.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ],
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
