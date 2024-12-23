import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<Map<String, dynamic>>> _leaderboardData;

  @override
  void initState() {
    super.initState();
    _leaderboardData = _leaderboardService.fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Back Button and Centered Title
              Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Title
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.emoji_events, // Trophy icon
                          color: Color(0xFFFFC107), // Gold color
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Daily Winners",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF083400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Back Button aligned to the left
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      margin:
                          const EdgeInsets.only(left: 0.0), // Ensure no overlap
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.mainFGColor,
                          width: 2,
                        ),
                      ),
                      width: 40.0,
                      height: 40.0,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.mainFGColor),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Celebration Text
              const Center(
                child: Text(
                  "🏆 Congratulations to today's champions! 🏆",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Leaderboard List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _leaderboardData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF083400),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Failed to load daily winners.",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    final leaderboard = snapshot.data ?? [];

                    if (leaderboard.isEmpty) {
                      return const Center(
                        child: Text(
                          "No winners available today.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = leaderboard[index];
                        final name = entry["Name"];
                        final profilePictureUrl = entry["ProfilePictureUrl"];
                        final challenge = entry["Challenge"];
                        final winningAmount = entry["WinningAmount"];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: profilePictureUrl != null
                                    ? NetworkImage(profilePictureUrl)
                                    : null,
                                child: profilePictureUrl == null
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF083400),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                "Challenge: $challenge\nWinning Amount: \$${winningAmount.toString()}",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF083400),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
