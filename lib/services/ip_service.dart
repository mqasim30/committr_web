// services/ip_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'log_service.dart';

class IPService {
  /// Fetches the user's public IP address.
  Future<String> fetchUserIP() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String ip = data['ip'];
        LogService.info("Fetched user IP: $ip");
        return ip;
      } else {
        LogService.error(
            "Failed to fetch IP. Status Code: ${response.statusCode}");
        return '';
      }
    } catch (e, stackTrace) {
      LogService.error("Exception while fetching IP: $e", e, stackTrace);
      return '';
    }
  }
}
