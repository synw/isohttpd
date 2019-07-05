import 'dart:async';
import 'dart:isolate';
import 'package:meta/meta.dart';

enum ServerStatus { started, stopped }

class IsoLogger {
  IsoLogger({@required this.logChannel, this.chan, this.verbose = false});

  final StreamController<String> logChannel;
  final SendPort chan;
  final bool verbose;

  void data(dynamic data) => _processMsg(data);

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

  void _processMsg(dynamic msg) {
    //if (verbose) print(msg);
    if (chan != null) chan.send(msg);
    if (msg is String) logChannel.sink.add(msg);
  }
}
