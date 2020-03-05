import 'dart:isolate';

import 'package:meta/meta.dart';

/// The logger
class IsoLogger {
  /// Default constructor
  IsoLogger({@required this.chan}) : assert(chan != null);

  /// The port to use
  final SendPort chan;

  /// Push something to the logs
  void push(dynamic obj) => chan.send(obj);
}
