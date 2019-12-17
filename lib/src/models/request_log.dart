import 'package:meta/meta.dart';

import '../types.dart';

/// A log message for request
class ServerRequestLog {
  /// Default constructor
  ServerRequestLog(
      {@required this.requestUrl,
      @required this.message,
      @required this.statusCode,
      @required this.logClass}) {
    time = DateTime.now().toLocal();
  }

  /// The time of the request
  DateTime time;

  /// The url
  String requestUrl;

  /// The log message
  final String message;

  /// The http status code
  final int statusCode;

  /// The log level
  final LogMessageClass logClass;

  @override
  String toString() {
    final date = "${time.hour}:${time.minute}:${time.second}";
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
    final msg = "$date $statusCode $msgClass $requestUrl $message";
    return msg;
  }
}
