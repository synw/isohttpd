import 'dart:io';
import '../logger.dart';

typedef Future<HttpResponse> IsoRequestHandler(
    HttpRequest request, IsoLogger log);

enum HttpdCommand { start, stop, status }

enum ServerError { alreadyStarted, notRunning }

enum ServerStatus { ready, started, stopped }
