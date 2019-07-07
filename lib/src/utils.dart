import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

Future<HttpResponse> jsonResponse(HttpRequest request, dynamic data) async {
  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType =
      ContentType("application", "json", charset: "utf-8");
  request.response.write(jsonEncode(data));
  return request.response;
}

Future<Map<String, List<Map<String, dynamic>>>> directoryListing(
    Directory dir) async {
  List contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  var dirs = <Map<String, String>>[];
  var files = <Map<String, dynamic>>[];
  for (var fileOrDir in contents) {
    if (fileOrDir is Directory) {
      var dir = Directory("${fileOrDir.path}");
      dirs.add({
        "name": p.basename(dir.path),
      });
    } else {
      var file = File("${fileOrDir.path}");
      files.add(<String, dynamic>{
        "name": p.basename(file.path),
        "size": file.lengthSync()
      });
    }
  }
  return {"files": files, "directories": dirs};
}
