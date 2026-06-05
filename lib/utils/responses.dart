import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response jsonError({
  required String message,
  required int statusCode,
}) {
  return Response.json(
    statusCode: statusCode,
    body: {'error': message},
  );
}

Response methodNotAllowed(List<String> methods) {
  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    headers: {'Allow': methods.join(', ')},
    body: {
      'error': 'Method not allowed.',
      'allowed_methods': methods,
    },
  );
}
