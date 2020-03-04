import 'dart:isolate';

import 'package:meta/meta.dart';

/// The logger
class IsoLogger {
  /// Default constructor
  IsoLogger({@required this.chan}) : assert(chan != null);

  /// The port to use
  final SendPort chan;

  /// Push a message to the debug channel
  void push(String msg) => _processMsg(msg);

  void _processMsg(String msg) {
    //print("SENDING MSG $msg");
    chan.send(msg);
  }
}
