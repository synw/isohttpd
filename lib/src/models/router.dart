import 'dart:io';

import 'package:meta/meta.dart';

import '../logger.dart';
import '../types.dart';

/// The http routed
class IsoRouter {
  /// Default constructor
  IsoRouter(this.routes);

  /// The available routes
  List<IsoRoute> routes;
}

/// Http route
class IsoRoute {
  /// If not [handler] is provided it will just print the request
  IsoRoute({@required this.path, this.handler}) {
    handler ??= (HttpRequest request, IsoLogger logSink) async {
      print("Request: ${request.uri}");
      return request.response;
    };
  }

  /// The url path
  final String path;

  /// The requests handler
  IsoRequestHandler handler;
}
