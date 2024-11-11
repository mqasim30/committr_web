import 'package:logger/logger.dart';

class LogService {
  static bool _isLoggingEnabled = false;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void enableLogging() {
    _isLoggingEnabled = true;
  }

  static void disableLogging() {
    _isLoggingEnabled = false;
  }

  static void debug(String message) {
    if (_isLoggingEnabled) {
      _logger.d(message);
    }
  }

  static void info(String message) {
    if (_isLoggingEnabled) {
      _logger.i(message);
    }
  }

  static void warning(String message) {
    if (_isLoggingEnabled) {
      _logger.w(message);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isLoggingEnabled) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
