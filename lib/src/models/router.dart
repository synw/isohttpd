import 'package:meta/meta.dart';
import 'types.dart';

class IsoRouter {
  IsoRouter(this.routes);

  List<IsoRoute> routes;
}

class IsoRoute {
  IsoRoute({@required this.path, this.handler}) {
    if (handler == null)
      throw (ArgumentError("Please provide a handler for the route"));
  }

  final String path;
  final IsoRequestHandler handler;
}
