import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

const _allowedMethods = 'GET, POST, PATCH, DELETE, OPTIONS';
const _allowedHeaders = 'Origin, Content-Type, Accept, Authorization';
const _maxAge = '86400';

Middleware cors() {
  return (handler) {
    return (context) async {
      final headers = _corsHeaders(context.request.headers);

      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: HttpStatus.noContent,
          headers: headers,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          ...headers,
        },
      );
    };
  };
}

Map<String, String> _corsHeaders(Map<String, String> requestHeaders) {
  final requestOrigin = requestHeaders['origin'] ?? requestHeaders['Origin'];
  final allowedOrigin = _allowedOriginFor(requestOrigin);

  return {
    HttpHeaders.accessControlAllowOriginHeader: allowedOrigin,
    HttpHeaders.accessControlAllowMethodsHeader: _allowedMethods,
    HttpHeaders.accessControlAllowHeadersHeader: _allowedHeaders,
    HttpHeaders.accessControlMaxAgeHeader: _maxAge,
    HttpHeaders.varyHeader: 'Origin',
  };
}

String _allowedOriginFor(String? requestOrigin) {
  final allowedOrigins = Platform.environment['CORS_ALLOWED_ORIGINS'];
  if (allowedOrigins == null || allowedOrigins.trim().isEmpty) {
    return '*';
  }

  final origins = allowedOrigins
      .split(',')
      .map((origin) => origin.trim())
      .where((origin) => origin.isNotEmpty)
      .toSet();

  if (requestOrigin != null && origins.contains(requestOrigin)) {
    return requestOrigin;
  }

  return origins.first;
}
