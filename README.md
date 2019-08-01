# Isohttpd

[![pub package](https://img.shields.io/pub/v/isohttpd.svg)](https://pub.dartlang.org/packages/isohttpd)

A lightweight http server that runs in an isolate. Powered by [Iso](https://github.com/synw/iso)

## Example

   ```dart
   import 'dart:io';
   import 'dart:async';
   import 'package:isohttpd/isohttpd.dart';

   Future<HttpResponse> handler(HttpRequest request, IsoLogger log) async {
     return jsonResponse(request, {"response": "ok"});
   }

   void main() async {
     // set routes
     final defaultRoute = IsoRoute(path: "*", handler: handler);
     final routes = <IsoRoute>[defaultRoute];
     final router = IsoRouter(routes);

     // run
     final iso = IsoHttpdRunner(host: "localhost", router: router);
     await iso.run(verbose: true);

     // listen to logs
     iso.logs.listen((String data) => print("$data"));
  iso.requestLogs.listen((ServerRequestLog data) => print("=> $data"));
     // idle
     final waiter = Completer<Null>();
     await waiter.future;
   }
   ```

## Commands

Start the server:

   ```dart
   await iso.run(startServer: false);
   iso.start();
   ```

Stop the server:

   ```dart
   iso.stop();
   ```

Server status:

   ```dart
   iso.status();
   ```

## Utils

Send a json response from a handler:

   ```dart
   jsonResponse(request, {"response": "ok"});
   ```

Decode multipart/form-data:

   ```dart
   final body = await decodeMultipartRequest(request);
   final dynamic data = body.data;
   ```

List a directory's content:

   ```dart
   final data = await directoryListing(Directory(somePath));
   ```
