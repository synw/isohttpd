import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'models/server_log.dart';
import 'types.dart';

/// The logger
class IsoLogger {
  /// Default constructor
  IsoLogger({@required this.logChannel, this.chan, this.verbose = false});

  /// The log stream
  final StreamController<IsoServerLog> logChannel;

  /// The port to use
  final SendPort chan;

  /// Verbosity
  final bool verbose;

  /// The log data
  void data(IsoServerLog logItem) => _processMsg(logItem);

  /// Warning level
  void warning(IsoServerLog logItem) {
    logItem.type = IsoLogType.warning;
    _processMsg(logItem);
  }

  /// Error level
  void error(IsoServerLog logItem) {
    logItem.type = IsoLogType.error;
    _processMsg(logItem);
  }

  /// Info level
  void info(IsoServerLog logItem) {
    logItem.type = IsoLogType.info;
    _processMsg(logItem);
  }

  /// Debug level
  void debug(IsoServerLog logItem) {
    logItem.type = IsoLogType.debug;
    _processMsg(logItem);
  }

  void _processMsg(IsoServerLog logItem) {
    if (verbose) {
      print(logItem.message);
    }
    if (chan != null) {
      chan.send(logItem.message);
    }
    logChannel.sink.add(logItem);
  }
}
