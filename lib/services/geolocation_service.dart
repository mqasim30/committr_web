// services/geolocation_service.dart

import 'package:http/http.dart' as http;
import 'log_service.dart';

class GeolocationService {
  /// Fetches the user's country based on their IP address.
  Future<String> fetchUserCountry(String ip) async {
    if (ip.isEmpty) {
      LogService.error("IP address is empty. Cannot fetch country.");
      return '';
    }

    try {
      final response =
          await http.get(Uri.parse('https://ipapi.co/$ip/country/'));

      if (response.statusCode == 200) {
        String country = response.body.trim();
        LogService.info("Fetched user country: $country");
        return country;
      } else {
        LogService.error(
            "Failed to fetch country. Status Code: ${response.statusCode}");
        return '';
      }
    } catch (e, stackTrace) {
      LogService.error("Exception while fetching country: $e", e, stackTrace);
      return '';
    }
  }
}
