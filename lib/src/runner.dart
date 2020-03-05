import 'dart:async';

import 'package:iso/iso.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:emodebug/emodebug.dart';

import 'models/request_log.dart';
import 'models/router.dart';
import 'models/state.dart';
import 'server.dart';
import 'types.dart';

/// The server runner class
class IsoHttpd {
  /// Default constructor
  IsoHttpd(
      {@required this.host,
      @required this.router,
      this.apiKey,
      this.port = 8084,
      this.textDebug = false}) {
    if (!textDebug) {
      _ = const EmoDebug(deactivatePrint: true);
    } else {
      _ = const EmoDebug(deactivatePrint: true, deactivateEmojis: true);
    }
  }

  /// The host to serve from
  final String host;

  /// The port
  int port;

  /// The iso router
  final IsoRouter router;

  /// an optional api key
  final String apiKey;

  /// Disable emojis in debug
  final bool textDebug;

  /// The main iso instance
  Iso iso;

  final _logsController = StreamController<dynamic>.broadcast();
  final _requestLogsController = StreamController<ServerRequestLog>.broadcast();
  StreamSubscription<dynamic> _dataOutSub;
  var _serverStartedCompleter = Completer<void>();
  final _ready = Completer<void>();
  bool _isRunning;
  EmoDebug _;

  /// Server logs stream
  Stream<dynamic> get logs => _logsController.stream;

  /// Request logs stream
  Stream<ServerRequestLog> get requestLogs => _requestLogsController.stream;

  /// The server has started event
  Future<void> get onServerStarted => _serverStartedCompleter.future;

  /// The server is ready to use
  Future get onReady => _ready.future;

  /// Is the server running?
  bool get isRunning => _isRunning;

  static Future<void> _run(IsoRunner isoRunner) async {
    isoRunner.receive();
    // get config from args
    IsoHttpdServer server;
    String _host;
    int _port;
    IsoRouter _router;
    String _apiKey;
    bool _startServer;
    final data = isoRunner.args[0] as Map<String, dynamic>;
    _host = data["host"] as String;
    _port = data["port"] as int;
    _router = data["router"] as IsoRouter;
    _startServer = data["start_server"] as bool;
    if (data.containsKey("api_key") == true) {
      _apiKey = data["api_key"] as String;
    }
    /*print("ROUTER $_router");
    for (final r in _router.routes) {
      print("- Route ${r.path} / ${r.handler}");
    }*/
    // init server instance
    server = IsoHttpdServer(
        host: _host,
        port: _port,
        router: _router,
        apiKey: _apiKey,
        chan: isoRunner.chanOut)
      ..init();
    isoRunner.send(ServerStatus.ready);
    //print('R > server init completed');
    if (_startServer) {
      //print("R > start server");
      await server.onReady;
      //chan.send("RCHAN > server ready");
      await server.start();
      isoRunner.send(ServerStatus.started);
      //chan.send("RCHAN > server started");
    }
    isoRunner.dataIn.listen((dynamic data) async {
      //print("R > DATA IN $data");
      final cmd = data as HttpdCommand;
      switch (cmd) {
        case HttpdCommand.start:
          if (server.status == ServerStatus.started) {
            isoRunner.send(ServerError.alreadyStarted);
          } else {
            await server.onReady;
            try {
              await server.start();
            } catch (_) {
              rethrow;
            }
            unawaited(server.onStarted
                .then((_) => isoRunner.send(ServerStatus.started)));
          }
          break;
        case HttpdCommand.stop:
          if (server.status == ServerStatus.stopped) {
            isoRunner.send(ServerError.notRunning);
          } else {
            try {
              server.stop();
              isoRunner.send(ServerStatus.stopped);
            } catch (e) {
              rethrow;
            }
          }
          break;
        case HttpdCommand.status:
          isoRunner.send(ServerState(server.status));
      }
    });
  }

  /// Start the server command
  void start() => iso.send(HttpdCommand.start);

  /// Stop the server command
  void stop() => iso.send(HttpdCommand.stop);

  /// Server status command
  void status() => iso.send(HttpdCommand.status);

  /// Run the server in an isolate
  Future<void> run({bool startServer = true}) async {
    assert(host != null);
    assert(router != null);
    iso = Iso(_run, onDataOut: (dynamic data) => null);

    // logs relay
    _dataOutSub = iso.dataOut.listen((dynamic data) {
      //print("DATA OUT $data / ${data.runtimeType}");
      if (data is ServerRequestLog) {
        //print("RUN > REQUEST LOG DATA $data");
        _addToRequestLogs(data);
      } else if (data is String) {
        _addToLogs(data);
      } else if (data is ServerStatus) {
        switch (data) {
          case ServerStatus.started:
            if (!_serverStartedCompleter.isCompleted) {
              _isRunning = true;
              _serverStartedCompleter.complete();
              _addToLogs(_.start("Server started at $host:$port"));
            }
            break;
          case ServerStatus.stopped:
            _serverStartedCompleter = Completer<void>();
            _isRunning = false;
            _addToLogs(_.stop("Server stopped"));
            break;
          case ServerStatus.ready:
            _ready.complete();
        }
      } else if (data is ServerError) {
        switch (data) {
          case ServerError.alreadyStarted:
            _addToLogs(_.warning("The server is already started"));
            break;
          case ServerError.notRunning:
            _addToLogs(_.warning("Error: the server is not running"));
            break;
        }
      } else if (data is ServerState) {
        String status;
        switch (data.status) {
          case ServerStatus.started:
            status = "running";
            break;
          case ServerStatus.stopped:
            status = "not running";
            break;
          default:
        }
        _addToLogs(_.msg("Server status: $status"));
      } else {
        //print("RUN > LOG DATA $data");
        _addToLogs(data);
      }
    });

    // configure the run function parameters
    final conf = <String, dynamic>{
      "host": host,
      "port": port,
      "router": router,
      "api_key": apiKey,
      "start_server": startServer
    };
    // run
    await iso.run(<dynamic>[conf]);
    await iso.onCanReceive;
  }

  /// Kill the server
  void kill() {
    iso.dispose();
    _dispose();
  }

  /// Dispose streams
  void _dispose() {
    _dataOutSub.cancel();
    _requestLogsController.close();
    _logsController.close();
  }

  void _addToLogs(dynamic obj) => _logsController.sink.add(obj);

  void _addToRequestLogs(ServerRequestLog data) =>
      _requestLogsController.sink.add(data);
}
