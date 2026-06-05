import 'package:dart_frog/dart_frog.dart';

Future<Map<String, dynamic>> readJsonObject(RequestContext context) async {
  final body = await context.request.json();

  if (body is! Map) {
    throw const FormatException('Expected JSON object.');
  }

  return Map<String, dynamic>.from(body);
}
