import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:emodebug/emodebug.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import 'logger.dart';
import 'models/request_log.dart';
import 'models/router.dart';
import 'request_logger.dart';
import 'types.dart';

/// The http server
class IsoHttpdServer {
  /// Provide a [host] and a [router]
  IsoHttpdServer(
      {@required this.host,
      @required this.router,
      @required this.chan,
      this.apiKey,
      this.port = 8084,
      this.textDebug = false})
      : assert(host != null) {
    log = IsoLogger(chan: chan);
    requestLogger =
        IsoRequestLogger(logChannel: _requestsLogChannel, chan: chan);
    if (!textDebug) {
      _ = const EmoDebug(deactivatePrint: true);
    } else {
      _ = const EmoDebug(deactivatePrint: true, deactivateEmojis: true);
    }
  }

  /// The hostname
  final String host;

  /// The server port
  final int port;

  /// The sendport to use
  final SendPort chan;

  /// The http router
  final IsoRouter router;

  /// The server api key
  final String apiKey;

  /// Disable emojis in debug
  final bool textDebug;

  /// The logger
  IsoLogger log;

  /// The requests logger
  IsoRequestLogger requestLogger;

  Stream<HttpRequest> _incomingRequests;
  bool _isRunning = false;
  bool _isInitialized = false;
  final _onStartedCompleter = Completer<void>();
  final _readyCompleter = Completer<void>();
  final _requestsLogChannel = StreamController<ServerRequestLog>.broadcast();
  final _logsChannel = StreamController<dynamic>.broadcast();
  StreamSubscription _incomingRequestsSub;
  HttpServer _server;
  EmoDebug _;

  /// The logs stream
  Stream<dynamic> get logs => _logsChannel.stream;

  /// The requests logs stream
  Stream<ServerRequestLog> get requestLogs => _requestsLogChannel.stream;

  /// Server is ready callback
  Future<void> get onReady => _readyCompleter.future;

  /// Server started callback
  Future<void> get onStarted => _onStartedCompleter.future;

  /// Is the server running
  bool get isRunning => _isRunning;

  /// The server status
  ServerStatus get status => _status();

  /// Initialize the server
  void init() {
    log.push("Initializing server at $host:$port");
    HttpServer.bind(host, port).then((HttpServer s) {
      _server = s;
      _incomingRequests = s.asBroadcastStream();
      _isInitialized = true;
      _readyCompleter.complete();
      log.push(_.init("Server initialized at $host:$port"));
    });
  }

  void _unauthorized(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.unauthorized;
    request.response.write(jsonEncode({"Status": "Unauthorized"}));
    request.response.close();
    requestLogger.warning(msg, request);
  }

  void _notFound(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({"Status": msg}));
    request.response.close();
    requestLogger.warning(msg, request);
  }

  /// Verify the api key
  bool verifyToken(HttpRequest request) {
    final tokenString = "Bearer $apiKey";
    try {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          tokenString) {
        return false;
      }
    } catch (e) {
      log.push(_.notFound("Can not read authorization header"));
      return false;
    }
    return true;
  }

  /// Start the server
  Future<void> start() async {
    assert(_isInitialized);
    log.push("Starting server");
    if (_isRunning) {
      log.push(_.warning("The server is already running"));
      return;
    }
    _isRunning = true;
    //log.debug("S > start > completing");
    if (!_onStartedCompleter.isCompleted) {
      _onStartedCompleter.complete();
    }

    _incomingRequestsSub = _incomingRequests.listen((request) {
      //log.debug("REQUEST ${request.uri.path} / ${request.headers.contentType}");
      // verify authorization
      if (apiKey != null) {
        final authorized = verifyToken(request);
        if (!authorized) {
          _unauthorized(request, "Unauthorized");
          return;
        }
      }
      // check method
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
      if (!isMethodAuthorized) {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        request.response.close();
        final msg = "Method not allowed ${request.method}";
        requestLogger.warning(msg, request);
        return;
      }
      // find a handler
      IsoRequestHandler handler;
      IsoRequestHandler defaultHandler;
      var found = false;
      for (final route in router.routes) {
        if (route.path == request.uri.path) {
          handler = route.handler;
          found = true;
          break;
        } else if (route.path == "*" && defaultHandler == null) {
          defaultHandler = route.handler;
        }
      }
      if (!found) {
        handler = defaultHandler;
      }

      // check if a route has been found
      if (handler == null) {
        const msg = "Not found";
        _notFound(request, msg);
        return;
      }
      // run the handler
      handler(request, log).then((HttpResponse response) {
        if (response.statusCode != HttpStatus.ok) {
          requestLogger.error("Status code ${response.statusCode}", request);
        } else if (response != null) {
          requestLogger.success("", request);
        }
        request.response.close();
        return;
      });
    });
  }

  /// Stop the server
  bool stop() {
    if (_isRunning) {
      _incomingRequestsSub.cancel();
      _isRunning = false;
      return true;
    }
    log.push(_.warning("The server is not running"));
    return false;
  }

  ServerStatus _status() {
    ServerStatus s;
    if (_isRunning == true) {
      s = ServerStatus.started;
    } else {
      s = ServerStatus.stopped;
    }
    return s;
  }

  /// Cleanup when finished using
  Future<void> dispose() async {
    await _server?.close();
    _server = null;
    unawaited(_requestsLogChannel.close());
    unawaited(_logsChannel.close());
  }
}
