import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:meta/meta.dart';

class IsoResponseLogger {
  IsoResponseLogger(
      {@required this.logChannel, this.chan, this.verbose = false});

  final StreamController<ServerResponseLog> logChannel;
  final SendPort chan;
  final bool verbose;

  void success(String msg, HttpRequest request) {
    var logItem = ServerResponseLog(
        logClass: LogMessageClass.success,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void warning(String msg, HttpRequest request) {
    var logItem = ServerResponseLog(
        logClass: LogMessageClass.warning,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void error(String msg, HttpRequest request) {
    var logItem = ServerResponseLog(
        logClass: LogMessageClass.error,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void _processMsg(ServerResponseLog logItem) {
    if (verbose) print(logItem);
    logChannel.sink.add(logItem);
    if (chan != null) chan.send(logItem);
  }
}

enum LogMessageClass { success, error, warning }

class ServerResponseLog {
  ServerResponseLog(
      {@required this.requestUrl,
      @required this.message,
      @required this.statusCode,
      @required this.logClass}) {
    time = DateTime.now().toLocal();
  }

  DateTime time;
  String requestUrl;
  final String message;
  final int statusCode;
  final LogMessageClass logClass;

  @override
  String toString() {
    String date = "${time.hour}:${time.minute}:${time.second}";
    String msgClass;
    switch (logClass) {
      case LogMessageClass.success:
        msgClass = "[OK]";
        break;
      case LogMessageClass.warning:
        msgClass = "[WARNING]";
        break;
      case LogMessageClass.error:
        msgClass = "[ERROR]";
        break;
      default:
    }
    if (requestUrl == "") requestUrl = "/";
    String msg = " $date $statusCode $msgClass $requestUrl $message";
    return msg;
  }
}
