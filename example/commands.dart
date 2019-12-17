import 'dart:async';
import 'dart:io';
import 'package:isohttpd/isohttpd.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
  log.debug(IsoServerLog(message: "Hello from request handler"));
  return jsonResponse(request, {"response": "ok"});
}

Future<String> initHost() async {
  final interfaces = await NetworkInterface.list(
      includeLoopback: false, type: InternetAddressType.any);
  return interfaces.first.addresses.first.address;
}

void main() async {
  /// set routes
  final defaultRoute = IsoRoute(path: "*", handler: handler);
  final routes = <IsoRoute>[defaultRoute];
  final router = IsoRouter(routes);

  /// set host
  final host = await initHost();

  /// init runner
  final iso = IsoHttpdRunner(host: host, router: router);

  /// listen to logs
  iso.logs.listen((IsoServerLog data) => print("$data"));
  iso.requestLogs.listen((ServerRequestLog data) => print("=> $data"));

  /// run
  print("Running the server in an isolate");
  await iso.run(startServer: false);
  iso
    ..status()
    ..start();
  await iso.onServerStarted;
  iso.status();
  await Future<Null>.delayed(Duration(seconds: 3));
  iso
    ..stop()
    ..status();
  //iso.dispose();
}
