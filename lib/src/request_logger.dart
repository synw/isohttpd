import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'models/request_log.dart';
import 'types.dart';

/// The requests logger
class IsoRequestLogger {
  /// Default constructor
  IsoRequestLogger(
      {@required this.logChannel, this.chan, this.verbose = false});

  /// The logs stream
  final StreamController<ServerRequestLog> logChannel;

  /// The port to use
  final SendPort chan;

  /// Verbosity
  final bool verbose;

  /// Success level
  void success(String msg, HttpRequest request) {
    final logItem = ServerRequestLog(
        logClass: LogMessageClass.success,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  /// Warning level
  void warning(String msg, HttpRequest request) {
    final logItem = ServerRequestLog(
        logClass: LogMessageClass.warning,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path,
        message: msg);
    _processMsg(logItem);
  }

  /// Error level
  void error(String msg, HttpRequest request) {
    final logItem = ServerRequestLog(
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
