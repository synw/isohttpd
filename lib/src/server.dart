import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import 'logger.dart';
import 'models/request_log.dart';
import 'models/router.dart';
import 'models/server_log.dart';
import 'request_logger.dart';
import 'types.dart';

/// The http server
class IsoHttpd {
  /// Provide a [host] and a [router]
  IsoHttpd(
      {@required this.host,
      @required this.router,
      this.port = 8084,
      this.apiKey,
      this.chan,
      this.verbose = false})
      : assert(host != null) {
    switch (chan != null) {
      case true:
        log = IsoLogger(logChannel: _logsChannel, chan: chan, verbose: verbose);
        requestLogger = IsoRequestLogger(
            logChannel: _requestsLogChannel, chan: chan, verbose: verbose);
        break;
      default:
        log = IsoLogger(logChannel: _logsChannel);
        requestLogger = IsoRequestLogger(logChannel: _requestsLogChannel);
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

  /// Verbosity
  final bool verbose;

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
  final _logsChannel = StreamController<IsoServerLog>.broadcast();
  StreamSubscription _incomingRequestsSub;
  HttpServer _server;

  /// The logs stream
  Stream<IsoServerLog> get logs => _logsChannel.stream;

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
    log.debug(IsoServerLog(message: "Initializing server at $host:$port"));
    HttpServer.bind(host, port).then((HttpServer s) {
      _server = s;
      _incomingRequests = s.asBroadcastStream();
      _isInitialized = true;
      _readyCompleter.complete();
      log.info(IsoServerLog(message: "Server initialized at $host:$port"));
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
    } catch (_) {
      log.error(IsoServerLog(message: "Can not get authorization header"));
      return false;
    }
    return true;
  }

  /// Start the server
  Future<void> start() async {
    assert(_isInitialized);
    log.info(IsoServerLog(message: "Starting server"));
    if (_isRunning) {
      log.warning(IsoServerLog(message: "The server is already running"));
      return;
    }
    _isRunning = true;
    //log.debug("S > start > completing");
    if (!_onStartedCompleter.isCompleted) {
      _onStartedCompleter.complete();
    }
    log.info(IsoServerLog(message: "Server started"));
    _incomingRequestsSub = _incomingRequests.listen((request) {
      //log.debug("REQUEST ${request.uri.path} / ${request.headers.contentType}");
      // verify authorization
      if (apiKey != null) {
        final authorized = verifyToken(request);
        if (!authorized) {
          _unauthorized(request, "Incorrect token");
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
      log.info(IsoServerLog(message: "Server stopped"));
      return true;
    }
    log.warning(IsoServerLog(message: "The server is not running"));
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
