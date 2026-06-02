import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Tagged, level-aware logger used everywhere instead of [debugPrint].
///
/// Behaviour:
/// - In debug/profile: all levels are emitted via `dart:developer.log`,
///   which integrates with DevTools and shows up in `flutter run` output.
/// - In release: only [LogLevel.info] and above are emitted; the goal is
///   to keep avatar / network telemetry while dropping verbose tracing.
///
/// Usage:
///   final log = Log('HeyGen');
///   log.i('connected to room');
///   log.w('keep_alive failed', error: e);
class Log {
  const Log(this.tag);

  final String tag;

  void d(String message) => _emit(LogLevel.debug, message);
  void i(String message) => _emit(LogLevel.info, message);
  void w(String message, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.warn, message, error: error, stack: stack);
  void e(String message, {Object? error, StackTrace? stack}) =>
      _emit(LogLevel.error, message, error: error, stack: stack);

  void _emit(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (kReleaseMode && level == LogLevel.debug) return;
    dev.log(
      message,
      name: tag,
      level: level.value,
      error: error,
      stackTrace: stack,
    );
  }
}

enum LogLevel {
  debug(500),
  info(800),
  warn(900),
  error(1000);

  const LogLevel(this.value);
  final int value;
}
