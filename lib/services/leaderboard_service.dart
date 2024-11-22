import 'package:firebase_database/firebase_database.dart';
import 'log_service.dart';

class LeaderboardService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  LeaderboardService();

  /// Fetches leaderboard data from the Realtime Database.
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      LogService.info("Fetching leaderboard data from Firebase.");
      DataSnapshot snapshot = await _databaseRef.child("LEADERBOARD").get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> leaderboard = data.entries
            .map((entry) => {
                  "Name": entry.value["Name"],
                  "ProfilePictureUrl": entry.value["ProfilePictureUrl"],
                  "Challenge": entry.value["Challenge"],
                  "WinningAmount": entry.value["WinningAmount"],
                })
            .toList();
        LogService.info("Successfully fetched leaderboard data.");
        return leaderboard;
      } else {
        LogService.warning("Leaderboard data does not exist.");
        return [];
      }
    } catch (e, stackTrace) {
      LogService.error("Error fetching leaderboard data: $e", e, stackTrace);
      return [];
    }
  }
}
