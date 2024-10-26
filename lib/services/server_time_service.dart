// lib/services/server_time_service.dart

import 'package:cloud_functions/cloud_functions.dart';

class ServerTimeService {
  static final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('getServerTime');

  static Future<DateTime> getServerTime() async {
    final result = await callable();
    final int serverTimeSeconds = result.data['serverTimeSeconds'];
    return DateTime.fromMillisecondsSinceEpoch(serverTimeSeconds * 1000);
  }
}
