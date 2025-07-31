// lib/services/url_parameter_service.dart

import 'dart:html' as html;
import '../services/log_service.dart';

class UrlParameterService {
  static String? _source;
  static String? _clickId;
  static bool _initialized = false;

  /// Extracts and stores URL parameters when the app loads
  static void initialize() {
    if (_initialized) return;

    try {
      final uri = Uri.parse(html.window.location.href);

      _source = uri.queryParameters['source'];
      _clickId = uri.queryParameters['clickid'];

      LogService.info("🔗 URL Parameters extracted:");
      LogService.info("🔗 Source: $_source");
      LogService.info("🔗 ClickID: $_clickId");

      _initialized = true;
    } catch (e) {
      LogService.error("Error extracting URL parameters: $e");
      _initialized = true; // Mark as initialized even if failed
    }
  }

  /// Gets the source parameter from URL, defaults to 'FlutterWeb' if not found
  static String getSource() {
    if (!_initialized) initialize();
    return _source ?? 'FlutterWeb';
  }

  /// Gets the clickid parameter from URL, returns null if not found
  static String? getClickId() {
    if (!_initialized) initialize();
    return _clickId;
  }

  /// Gets both parameters as a map
  static Map<String, String?> getParameters() {
    if (!_initialized) initialize();
    return {
      'source': _source,
      'clickid': _clickId,
    };
  }

  /// Check if we have any tracking parameters
  static bool hasTrackingParameters() {
    if (!_initialized) initialize();
    return _source != null || _clickId != null;
  }

  /// Clear stored parameters (useful for testing)
  static void clear() {
    _source = null;
    _clickId = null;
    _initialized = false;
  }
}
