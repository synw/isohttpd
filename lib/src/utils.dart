import 'dart:io';
import 'dart:convert';

Future<HttpResponse> jsonResponse(HttpRequest request, dynamic data) async {
  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType =
      ContentType("application", "json", charset: "utf-8");
  request.response.write(jsonEncode(data));
  return request.response;
}
