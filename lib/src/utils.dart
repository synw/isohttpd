import 'dart:convert';
import 'dart:io';

import 'package:body_parser/body_parser.dart';
import 'package:path/path.dart' as p;

Future<HttpResponse> jsonResponse(HttpRequest request, dynamic data) async {
  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType =
      ContentType("application", "json", charset: "utf-8");
  request.response.write(jsonEncode(data));
  return request.response;
}

Future<BodyParseResult> decodeMultipartRequest(HttpRequest request) async =>
    parseBody(request);

Future<Map<String, List<Map<String, dynamic>>>> directoryListing(
    Directory dir) async {
  final contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  final dirs = <Map<String, String>>[];
  final files = <Map<String, dynamic>>[];
  for (final fileOrDir in contents) {
    if (fileOrDir is Directory) {
      final dir = Directory("${fileOrDir.path}");
      dirs.add({
        "name": p.basename(dir.path),
      });
    } else {
      final file = File("${fileOrDir.path}");
      files.add(<String, dynamic>{
        "name": p.basename(file.path),
        "size": file.lengthSync()
      });
    }
  }
  return {"files": files, "directories": dirs};
}
