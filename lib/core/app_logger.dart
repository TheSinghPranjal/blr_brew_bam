import 'package:flutter/foundation.dart';

/// Structured, tagged logger for the app.
///
/// Usage:
///   static const _log = AppLogger('MyClassName');
///   _log.info('Something happened');
///   _log.error('Failed', e, stackTrace);
class AppLogger {
  final String tag;

  const AppLogger(this.tag);

  void debug(String msg) {
    if (kDebugMode) debugPrint('[$tag] 🔵 $msg');
  }

  void info(String msg) {
    if (kDebugMode) debugPrint('[$tag] ✅ $msg');
  }

  void warn(String msg) {
    if (kDebugMode) debugPrint('[$tag] ⚠️  $msg');
  }

  void error(String msg, [Object? err, StackTrace? stack]) {
    debugPrint('[$tag] ❌ $msg${err != null ? '\n  cause: $err' : ''}');
    if (stack != null && kDebugMode) {
      debugPrint(stack.toString());
    }
  }
}
