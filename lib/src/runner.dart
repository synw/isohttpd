import 'dart:async';
import 'package:meta/meta.dart';
import 'package:iso/iso.dart';
import 'server.dart';
import 'models/router.dart';
import 'models/types.dart';
import 'models/request_log.dart';

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

  Stream<dynamic> get logs => _logsController.stream;
  Stream<dynamic> get requestLogs => _requestLogsController.stream;

  static void _run(IsoRunner iso) async {
    iso.receive();
    //iso.send("R IS > Running");

    // get config from args
    IsoHttpd server;
    String _host;
    int _port;
    IsoRouter _router;
    String _apiKey;
    bool _startServer;
    bool _verbose;
    dynamic data = iso.args[0] as Map<String, dynamic>;
    _host = data["host"] as String;
    _port = data["port"] as int;
    _router = data["router"] as IsoRouter;
    _startServer = data["start_server"] as bool;
    _verbose = data["verbose"] as bool;
    if (data.containsKey("api_key") == true)
      _apiKey = data["api_key"] as String;

    //print("R > config: $data");
    //print('R > on data in');
    //dataIn.listen((dynamic data) {
    //  print("R > DATA IN $data");
    //});
    /*
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
    });*/
    //iso.send("R IS > test");
    // init server instance
    server = IsoHttpd(
        host: _host,
        port: _port,
        router: _router,
        apiKey: _apiKey,
        chan: iso.chanOut,
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
      if (data is ServerRequestLog) {
        //print("RUN > REQUEST LOG DATA $data");
        _requestLogsController.sink.add(data);
      } else {
        //print("RUN > LOG DATA $data");
        _logsController.sink.add(data);
      }
    });

    // configure the run function parameters
    Map<String, dynamic> conf = <String, dynamic>{
      "host": host,
      "port": 8084,
      "router": router,
      "api_key": apiKey,
      "start_server": startServer,
      "verbose": verbose,
    };
    // run
    iso.run(<dynamic>[conf]);

    //await iso.onReady;
  }

  void kill() {
    iso.kill();
  }

  void dispose() {
    _dataOutSub.cancel();
    _logsController.close();
  }
}
