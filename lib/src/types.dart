import 'dart:async';
import 'dart:io';

import 'logger.dart';

typedef IsoRequestHandler = Future<HttpResponse> Function(
    HttpRequest request, IsoLogger log);

/// The server commands
enum HttpdCommand {
  /// Start the server
  start,

  /// Stop the server
  stop,

  /// Check the server status
  status
}

/// The error types
enum ServerError {
  /// The server is already started
  alreadyStarted,

  /// The server is not started
  notRunning
}

/// The server status
enum ServerStatus {
  /// The server is ready
  ready,

  /// The server is started
  started,

  /// The server is stopped
  stopped
}

/// The log level
enum LogMessageClass {
  /// Succes message
  success,

  /// Error message
  error,

  /// Warning message
  warning
}

/// The request log type
enum IsoLogType {
  /// Debug level
  debug,

  /// Info level
  info,

  /// Warning level
  warning,

  /// Error level
  error,
}
