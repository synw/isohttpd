import 'package:meta/meta.dart';

import '../types.dart';

/// Server log message
class IsoServerLog {
  /// Default constructor
  IsoServerLog(
      {@required this.message,
      this.type,
      this.requestUrl,
      this.eventType,
      this.payload,
      this.date,
      this.statusCode});

  /// The log level
  IsoLogType type;

  /// The message
  final String message;

  /// The server event
  final IsoServerEventType eventType;

  /// The event date
  final DateTime date;

  /// The requested url
  final String requestUrl;

  /// The http status code
  final int statusCode;

  /// The log payload
  final dynamic payload;

  @override
  String toString() {
    final msg = "$message";
    return msg;
  }
}
