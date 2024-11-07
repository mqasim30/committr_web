// lib/services/server_time_service.dart

import 'package:Committr/services/log_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ServerTimeService {
  static final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('getServerTime');

  /// Fetches server time and returns it in the user's local time zone.
  static Future<DateTime> getServerTime() async {
    try {
      final result = await callable();
      final int serverTimeSeconds = result.data['serverTimeSeconds'];
      // Converts epoch seconds to local DateTime
      return DateTime.fromMillisecondsSinceEpoch(serverTimeSeconds * 1000);
    } catch (e) {
      // Handle the error, e.g., log it or notify the user
      LogService.error('Error fetching server time: $e');
      return DateTime.now(); // Fallback to local time
    }
  }

  /// Fetches server time and returns it as a UTC DateTime object.
  static Future<DateTime> getServerTimeUtc() async {
    try {
      final result = await callable();
      final int serverTimeSeconds = result.data['serverTimeSeconds'];
      // Converts epoch seconds to UTC DateTime
      return DateTime.fromMillisecondsSinceEpoch(serverTimeSeconds * 1000,
          isUtc: true);
    } catch (e) {
      // Handle the error, e.g., log it or notify the user
      LogService.error('Error fetching server UTC time: $e');
      return DateTime.now().toUtc(); // Fallback to current UTC time
    }
  }
}
