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
      {@required this.message,
      this.tyoe,
      this.requestUrl,
      this.eventType,
      this.payload,
      this.statusCode});

  IsoLogType tyoe;
  String message;
  IsoServerEventType eventType;
  DateTime date;
  String requestUrl;
  int statusCode;
  dynamic payload;

  @override
  String toString() {
    final msg = "$message";
    return msg;
  }
}
