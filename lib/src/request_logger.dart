import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'models/request_log.dart';

class IsoRequestLogger {
  IsoRequestLogger(
      {@required this.logChannel, this.chan, this.verbose = false});

  final StreamController<ServerRequestLog> logChannel;
  final SendPort chan;
  final bool verbose;

  void success(String msg, HttpRequest request) {
    var logItem = ServerRequestLog(
        logClass: LogMessageClass.success,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void warning(String msg, HttpRequest request) {
    var logItem = ServerRequestLog(
        logClass: LogMessageClass.warning,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void error(String msg, HttpRequest request) {
    var logItem = ServerRequestLog(
        logClass: LogMessageClass.error,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  void _processMsg(ServerRequestLog logItem) {
    //if (verbose) print(logItem);
    logChannel.sink.add(logItem);
    if (chan != null) chan.send(logItem);
  }
}
