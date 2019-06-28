import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:isohttpd/isohttpd.dart';
import 'package:isohttpd/src/models/router.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:body_parser/body_parser.dart';
import 'models/response_log.dart';
import 'models/log.dart';

class IsoHttpd {
  IsoHttpd(
      {@required this.host,
      this.port = 8084,
      @required this.router,
      this.apiKey,
      this.chan,
      this.verbose = false})
      : assert(host != null) {
    switch (chan != null) {
      case true:
        log = IsoLogger(logChannel: _logsChannel, chan: chan, verbose: verbose);
        serverLog = IsoResponseLogger(
            logChannel: _requestsLogChannel, chan: chan, verbose: verbose);
        break;
      default:
        log = IsoLogger(logChannel: _logsChannel);
        serverLog = IsoResponseLogger(logChannel: _requestsLogChannel);
    }
  }

  final String host;
  final int port;
  final SendPort chan;
  final IsoRouter router;
  final String apiKey;
  final bool verbose;

  IsoLogger log;
  IsoResponseLogger serverLog;
  Stream<HttpRequest> _incomingRequests;
  bool _isRunning = false;
  bool _isInitialized = false;
  final Completer<Null> _onStartedCompleter = Completer<Null>();
  final Completer<Null> _readyCompleter = Completer<Null>();
  final StreamController<ServerResponseLog> _requestsLogChannel =
      StreamController<ServerResponseLog>.broadcast();
  final StreamController<String> _logsChannel =
      StreamController<String>.broadcast();
  StreamSubscription _incomingRequestsSub;

  Stream<String> get logs => _logsChannel.stream;
  Stream<ServerResponseLog> get requestLogs => _requestsLogChannel.stream;

  Future<Null> get onReady => _readyCompleter.future;
  Future<Null> get onStarted => _onStartedCompleter.future;
  bool get isRunning => _isRunning;

  static Future<BodyParseResult> decodeMultipartRequest(
          HttpRequest request) async =>
      await parseBody(request);

  void init() {
    log.info("Initializing server at $host:$port");
    HttpServer.bind(host, port).then((HttpServer s) {
      //print('S > bind');
      _incomingRequests = s.asBroadcastStream();
      _isInitialized = true;
      _readyCompleter.complete();
      log.info("Server initialized");
      //print('S > end bind');
    });
  }

  void _unauthorized(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.unauthorized;
    request.response.write(jsonEncode({"Status": "Unauthorized"}));
    request.response.close();
    serverLog.warning(msg, request);
  }

  void _notFound(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({"Status": msg}));
    request.response.close();
    serverLog.warning(msg, request);
  }

  bool verifyToken(HttpRequest request) {
    String tokenString = "Bearer $apiKey";
    //print("HEADERS");
    //print("${request.headers}");
    try {
      if (request.headers.value(HttpHeaders.authorizationHeader) != tokenString)
        return false;
    } catch (_) {
      log.error("Can not get authorization header");
      return false;
    }
    return true;
  }

  Future<void> start() async {
    assert(_isInitialized);
    log.info("Starting server");
    if (_isRunning) {
      log.warning("The server is already running");
      return;
    }
    _isRunning = true;
    //log.debug("S > start > completing");
    if (!_onStartedCompleter.isCompleted) _onStartedCompleter.complete();
    log.info("Server started");
    _incomingRequestsSub = _incomingRequests.listen((request) {
      //log.debug("REQUEST ${request.uri.path} / ${request.headers.contentType}");
      // verify authorization
      if (apiKey != null) {
        bool authorized = verifyToken(request);
        if (!authorized) {
          _unauthorized(request, "Incorrect token");
          return;
        }
      }
      // find a handler
      IsoRequestHandler handler;
      bool isMethodAuthorized;
      switch (request.method) {
        case 'POST':
          isMethodAuthorized = true;
          break;
        case 'GET':
          isMethodAuthorized = true;
          break;
        default:
          isMethodAuthorized = false;
      }
      if (isMethodAuthorized) {
        for (final route in router.routes) {
          if ((route.path == request.uri.path || route.path == "*") &&
              route.handler != null) {
            handler = route.handler;
            break;
          }
        }
      } else {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        request.response.close();
        String msg = "Method not allowed ${request.method}";
        serverLog.warning(msg, request);
        return;
      }
      // run the handler
      if (handler == null) {
        String msg = "Handler not found";
        _notFound(request, msg);
        return;
      }
      handler(request, log).then((HttpResponse response) {
        if (response != null) serverLog.success("", request);
        request.response.close();
        return;
      });
    });
  }

  Future<bool> stop() async {
    if (_isRunning) {
      _incomingRequestsSub.cancel();
      _isRunning = false;
      log.info("Server stopped");
      return true;
    }
    log.warning("The server is already running");
    return false;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getDirectoryListing(
      Directory dir) async {
    List contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    var dirs = <Map<String, String>>[];
    var files = <Map<String, dynamic>>[];
    for (var fileOrDir in contents) {
      if (fileOrDir is Directory) {
        var dir = Directory("${fileOrDir.path}");
        dirs.add({
          "name": p.basename(dir.path),
        });
      } else {
        var file = File("${fileOrDir.path}");
        files.add(<String, dynamic>{
          "name": p.basename(file.path),
          "size": file.lengthSync()
        });
      }
    }
    return {"files": files, "directories": dirs};
  }

  void dispose() async {
    _requestsLogChannel.close();
    _logsChannel.close();
  }
}
