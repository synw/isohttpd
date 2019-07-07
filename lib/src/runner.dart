import 'dart:async';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';
import 'package:iso/iso.dart';
import 'server.dart';
import 'models/router.dart';
import 'models/types.dart';
import 'models/request_log.dart';
import 'models/state.dart';

class IsoHttpdRunner {
  IsoHttpdRunner(
      {@required this.host,
      this.port = 8084,
      @required this.router,
      this.apiKey,
      this.verbose = false});

  final String host;
  int port;
  final IsoRouter router;
  final String apiKey;
  final bool verbose;

  Iso iso;
  final StreamController<dynamic> _logsController = StreamController<dynamic>();
  final StreamController<dynamic> _requestLogsController =
      StreamController<dynamic>();
  StreamSubscription<dynamic> _dataOutSub;
  var _serverStartedCompleter = Completer<Null>();

  Stream<dynamic> get logs => _logsController.stream;
  Stream<dynamic> get requestLogs => _requestLogsController.stream;
  Future<Null> get onServerStarted => _serverStartedCompleter.future;

  static void _run(IsoRunner isoRunner) async {
    isoRunner.receive();
    //iso.send("R IS > Running");

    // get config from args
    IsoHttpd server;
    String _host;
    int _port;
    IsoRouter _router;
    String _apiKey;
    bool _startServer;
    bool _verbose;
    dynamic data = isoRunner.args[0] as Map<String, dynamic>;
    _host = data["host"] as String;
    _port = data["port"] as int;
    _router = data["router"] as IsoRouter;
    _startServer = data["start_server"] as bool;
    _verbose = data["verbose"] as bool;
    if (data.containsKey("api_key") == true)
      _apiKey = data["api_key"] as String;
    /*print("ROUTER $_router");
    for (final r in _router.routes) {
      print("- Route ${r.path} / ${r.handler}");
    }*/
    // init server instance
    server = IsoHttpd(
        host: _host,
        port: _port,
        router: _router,
        apiKey: _apiKey,
        chan: isoRunner.chanOut,
        verbose: _verbose);
    //print('R > init server');
    server.init();
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
      HttpdCommand cmd = data as HttpdCommand;
      switch (cmd) {
        case HttpdCommand.start:
          if (server.status == ServerStatus.started)
            isoRunner.send(ServerError.alreadyStarted);
          else {
            await server.onReady;
            await server
                .start()
                .catchError((dynamic e) => throw ("Can not start server $e"));
            server.onStarted.then((_) => isoRunner.send(ServerStatus.started));
          }
          break;
        case HttpdCommand.stop:
          if (server.status == ServerStatus.stopped)
            isoRunner.send(ServerError.notRunning);
          else {
            try {
              server.stop();
              isoRunner.send(ServerStatus.stopped);
            } catch (e) {
              throw ("Can not stop server $e");
            }
          }
          break;
        case HttpdCommand.status:
          isoRunner.send(ServerState(server.status));
      }
    });
    //print("R print > Runner is running");
    //iso.send("R IS > Runner is running");
    //iso.receive();
  }

  void start() => iso.send(HttpdCommand.start);

  void stop() => iso.send(HttpdCommand.stop);

  void status() => iso.send(HttpdCommand.status);

  Future<void> run({bool startServer = true, bool verbose = false}) async {
    assert(host != null);
    assert(router != null);
    iso = Iso(_run, onDataOut: (dynamic data) => null);

    // logs relay
    _dataOutSub = iso.dataOut.listen((dynamic data) {
      //print("DATA OUT $data");
      if (data is ServerRequestLog) {
        //print("RUN > REQUEST LOG DATA $data");
        _addToRequestLogs(data);
      } else if (data is ServerStatus) {
        switch (data) {
          case ServerStatus.started:
            if (!_serverStartedCompleter.isCompleted)
              _serverStartedCompleter.complete();
            break;
          case ServerStatus.stopped:
            _serverStartedCompleter = Completer<Null>();
        }
      } else if (data is ServerError) {
        switch (data) {
          case ServerError.alreadyStarted:
            _addToLogs("Error: the server is already started");
            break;
          case ServerError.notRunning:
            _addToLogs("Error: the server is not running");
        }
      } else if (data is ServerState) {
        String status;
        switch (data.status) {
          case ServerStatus.started:
            status = "running";
            break;
          case ServerStatus.stopped:
            status = "not running";
        }
        _addToLogs("Server status: $status");
      } else {
        //print("RUN > LOG DATA $data");
        _addToLogs(data);
      }
    });

    // configure the run function parameters
    Map<String, dynamic> conf = <String, dynamic>{
      "host": host,
      "port": port,
      "router": router,
      "api_key": apiKey,
      "start_server": startServer,
      "verbose": verbose,
    };
    // run
    await iso.run(<dynamic>[conf]);
    await iso.onCanReceive;
  }

  void kill() {
    iso.kill();
  }

  void dispose() {
    _dataOutSub.cancel();
    _logsController.close();
  }

  void _addToLogs(dynamic data) {
    if (verbose) print("$data");
    _logsController.sink.add(data);
  }

  void _addToRequestLogs(dynamic data) {
    if (verbose) print("$data");
    _requestLogsController.sink.add(data);
  }
}
