import 'dart:io';
import 'package:isohttpd/isohttpd.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
  var response = jsonResponse(request, {"response": "ok"});
  return response;
}

Future<String> initHost() async {
  final interfaces = await NetworkInterface.list(
      includeLoopback: false, type: InternetAddressType.any);
  return interfaces.first.addresses.first.address;
}

void main() async {
  // set routes
  IsoRoute onGet = IsoRoute(path: "*", handler: handler);
  List<IsoRoute> routes = <IsoRoute>[onGet];
  final router = IsoRouter(routes);
  // set host
  String host = await initHost();
  // run
  print("Running the server in an isolate");
  IsoHttpdRunner iso = IsoHttpdRunner(host: host, router: router);
  await iso.run(verbose: true);
  // listen to logs
  iso.logs.listen((dynamic data) => print("$data"));
  iso.requestLogs.listen((dynamic data) => print("REQUEST $data"));
  // idle
  while (true) {}
}
