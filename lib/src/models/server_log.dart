import 'package:meta/meta.dart';

enum IsoLogType {
  debug,
  info,
  warning,
  error,
}

enum IsoServerEventType { initialization, startServer, stopServer }

class IsoServerLog {
  IsoServerLog(
      {@required this.message, this.tyoe, this.payload, this.eventType});

  IsoLogType tyoe;
  String message;
  dynamic payload;
  IsoServerEventType eventType;
  DateTime date;

  @override
  String toString() {
    final msg = "$message";
    return msg;
  }
}
