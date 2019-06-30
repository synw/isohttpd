import 'dart:io';
import 'package:meta/meta.dart';
import 'log.dart';
import 'types.dart';

class IsoRouter {
  IsoRouter(this.routes);

  List<IsoRoute> routes;
}

class IsoRoute {
  IsoRoute({@required this.path, this.handler}) {
    handler ??= (HttpRequest request, IsoLogger logger) async {
      print("Request: ${request.uri}");
      return request.response;
    };
  }

  final String path;
  IsoRequestHandler handler;
}
