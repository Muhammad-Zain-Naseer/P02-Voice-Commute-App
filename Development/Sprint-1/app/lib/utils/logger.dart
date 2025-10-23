import 'package:flutter/foundation.dart';

/// Custom logger that prints to console
/// Note: debugPrint already shows in both Flutter console and browser DevTools
class Logger {
  static void log(String message) {
    debugPrint(message);
  }

  static void error(String message) {
    debugPrint('ERROR: $message');
  }
}
