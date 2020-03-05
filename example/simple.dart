import 'dart:async';
import 'dart:io';

import 'package:isohttpd/isohttpd.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
  log.push("Hello from request handler");
  return jsonResponse(request, {"response": "ok"});
}

Future<String> initHost() async {
  final interfaces = await NetworkInterface.list(
      includeLoopback: false, type: InternetAddressType.any);
  return interfaces.first.addresses.first.address;
}

Future<void> main() async {
  /// set routes
  final defaultRoute = IsoRoute(path: "*", handler: handler);
  final routes = <IsoRoute>[defaultRoute];
  final router = IsoRouter(routes);

  /// set host
  final host = await initHost();

  /// init runner
  final iso = IsoHttpd(host: host, router: router);

  /// listen to logs
  iso.logs.listen((dynamic msg) => print("[server log] $msg"));
  iso.requestLogs.listen((ServerRequestLog data) => print("=> $data"));

  /// run
  print("Running the server in an isolate");
  await iso.run();
}
