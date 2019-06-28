import 'dart:async';
import 'dart:isolate';
import 'package:meta/meta.dart';

class IsoLogger {
  IsoLogger({@required this.logChannel, this.chan, this.verbose = false});

  final StreamController<String> logChannel;
  final SendPort chan;
  final bool verbose;

  void warning(String msg) {
    msg = "Warning: $msg";
    _processMsg(msg);
  }

  void error(String msg) {
    msg = "Error: $msg";
    _processMsg(msg);
  }

  void info(String msg) {
    msg = "Info: $msg";
    _processMsg(msg);
  }

  void debug(String msg) {
    msg = "Debug: $msg";
    _processMsg(msg);
  }

  void _processMsg(String msg) {
    if (verbose) print(msg);
    if (chan != null) chan.send(msg);
    logChannel.sink.add(msg);
  }
}
