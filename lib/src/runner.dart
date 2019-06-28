import 'dart:async';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'package:iso/iso.dart';
import 'server.dart';
import 'models/router.dart';
import 'models/types.dart';

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
  final StreamController<dynamic> __logsController =
      StreamController<dynamic>();
  final StreamController<dynamic> _requestLogsController =
      StreamController<dynamic>();

  Stream<dynamic> get logs => __logsController.stream;
  Stream<dynamic> get requestLogs => _requestLogsController.stream;

  static void _run(SendPort chan) async {
    //print("R > run runner run");
    IsoHttpd server;
    Completer _completer = Completer<Null>();
    String _host;
    int _port;
    IsoRouter _router;
    String _apiKey;
    bool _startServer;
    bool _verbose;
    //print('R > on data in');
    Iso.onDataIn(chan, (dynamic data) {
      //print("R > runner data in: $data");
      if (data is Map) {
        _host = data["host"] as String;
        _port = data["port"] as int;
        _router = data["router"] as IsoRouter;
        _startServer = data["start_server"] as bool;
        _verbose = data["verbose"] as bool;
        if (data.containsKey("api_key")) _apiKey = data["api_key"] as String;
        if (!_completer.isCompleted) _completer.complete();
      }
      if (data is HttpdCommand) {
        print("R > COMMAND $data");
        switch (data) {
          case HttpdCommand.start:
            server.start().catchError((dynamic e) {
              throw ("Can not start server $e");
            });
            break;
          case HttpdCommand.stop:
            server.stop().catchError((dynamic e) {
              throw ("Can not stop server $e");
            });
            break;
          case HttpdCommand.status:
            //server.isRunning;
            break;
        }
      }
    });
    //print('R > wait runner completed');
    await _completer.future;
    server = IsoHttpd(
        host: _host,
        port: _port,
        router: _router,
        apiKey: _apiKey,
        chan: chan,
        verbose: _verbose);
    //print('R > init server');
    server.init();
    //print('R > server init completed');
    if (_startServer) {
      //print("R > start server");
      //chan.send("RCHAN > init server");
      //print("R > waiting server ready");
      await server.onReady;
      //chan.send("RCHAN > server ready");
      await server.start();
      //chan.send("RCHAN > server started");
    }
  }

  void start() => iso.send(HttpdCommand.start);

  void stop() => iso.send(HttpdCommand.stop);

  void status() => iso.send(HttpdCommand.status);

  Future<void> run({bool startServer = true, bool verbose = false}) async {
    assert(host != null);
    iso =
        Iso(_run, onDataOut: (dynamic data) => __logsController.sink.add(data));
    iso.run();
    await iso.onReady;
    //print("RUN > iso ready");
    Map<String, dynamic> conf = <String, dynamic>{
      "host": host,
      "port": 8084,
      "router": router,
      "api_key": apiKey,
      "start_server": startServer,
      "verbose": verbose,
    };
    //print('RUN : sending conf');
    iso.send(conf);
  }

  void kill() {
    iso.kill();
  }

  void dispose() {
    __logsController.close();
  }
}
