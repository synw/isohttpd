import 'dart:io';
import 'package:isohttpd/isohttpd.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
  var response = jsonResponse(request, {"response": "ok"});
  return response;
}

void main() async {
  final onGet = IsoRoute(path: "*", handler: handler);
  final routes = <IsoRoute>[onGet];
  final router = IsoRouter(routes);
  var server = IsoHttpd(host: "localhost", router: router);
  server.logs.listen((dynamic data) => print("LOG: $data"));
  server.requestLogs.listen((dynamic data) => print("REQUEST LOG: $data"));
  server.init();
  await server.onReady;
  server.start();
}
