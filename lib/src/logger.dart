import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'models/server_log.dart';

class IsoLogger {
  IsoLogger({@required this.logChannel, this.chan, this.verbose = false});

  final StreamController<IsoServerLog> logChannel;
  final SendPort chan;
  final bool verbose;

  void data(IsoServerLog logItem) => _processMsg(logItem);

  void warning(IsoServerLog logItem) {
    logItem.tyoe = IsoLogType.warning;
    _processMsg(logItem);
  }

  void error(IsoServerLog logItem) {
    logItem.tyoe = IsoLogType.error;
    _processMsg(logItem);
  }

  void info(IsoServerLog logItem) {
    logItem.tyoe = IsoLogType.info;
    _processMsg(logItem);
  }

  void debug(IsoServerLog logItem) {
    logItem.tyoe = IsoLogType.debug;
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
