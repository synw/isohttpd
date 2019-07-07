import 'dart:async';
import 'dart:io';
import 'package:isohttpd/isohttpd.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
  log.debug("Hello from request handler");
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
  String host = await initHost();

  /// init runner
  final iso = IsoHttpdRunner(host: host, router: router);

  /// listen to logs
  iso.logs.listen((dynamic data) => print("$data"));
  iso.requestLogs.listen((dynamic data) => print("=> $data"));

  /// run
  print("Running the server in an isolate");
  iso.run();
}
