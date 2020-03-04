import 'dart:isolate';

import 'package:meta/meta.dart';

/// The logger
class IsoLogger {
  /// Default constructor
  IsoLogger({@required this.chan});

  /// The log stream
  //final StreamController<String> logChannel;

  /// The port to use
  final SendPort chan;

  /// The log data
  //void data(dynamic e) => _processMsg(logItem);

  /// Push a message to the debug channel
  void push(String msg) => _processMsg(msg);

  void _processMsg(String msg) => chan.send("CHAN $msg");
  /*if (chan != null) {
      chan.send("CHAN $msg");
    }*/
//    logChannel.sink.add(msg);
  //}
}
