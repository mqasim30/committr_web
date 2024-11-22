import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text(
          "Leaderboard",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF083400),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                "Failed to load leaderboard data.",
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
                "No leaderboard data available.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Card(
                  elevation: 3,
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
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF083400),
                      ),
                    ),
                    subtitle: Text(
                      "Challenge: $challenge\nWinning Amount: \$${winningAmount.toString()}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
