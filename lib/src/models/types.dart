import 'dart:io';
import 'log.dart';

typedef Future<HttpResponse> IsoRequestHandler(
    HttpRequest request, IsoLogger log);

enum HttpdCommand { start, stop, status }

enum ServerError { alreadyStarted, notRunning }

enum ServerStatus { started, stopped }
