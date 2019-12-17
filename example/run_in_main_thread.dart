import 'dart:io';

import 'package:isohttpd/isohttpd.dart';
import 'package:pedantic/pedantic.dart';

Future<HttpResponse> handler(HttpRequest request, IsoLogger log) =>
    jsonResponse(request, {"response": "ok"});

Future<void> main() async {
  final onGet = IsoRoute(path: "*", handler: handler);
  final routes = <IsoRoute>[onGet];
  final router = IsoRouter(routes);
  final server = IsoHttpd(host: "localhost", router: router);
  server.logs.listen((dynamic data) => print("LOG: $data"));
  server.requestLogs.listen((dynamic data) => print("REQUEST LOG: $data"));
  server.init();
  await server.onReady;
  unawaited(server.start());
}
