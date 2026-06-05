import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/utils/responses.dart';

Middleware requireAuthentication() {
  return (handler) {
    return (context) async {
      final token = _bearerTokenFrom(context.request.headers);
      if (token == null) {
        return jsonError(
          message: 'Missing or invalid Authorization header.',
          statusCode: HttpStatus.unauthorized,
        );
      }

      final authService = context.read<AuthService>();
      final user = await authService.userFromToken(token);

      if (user == null) {
        return jsonError(
          message: 'Invalid or expired token.',
          statusCode: HttpStatus.unauthorized,
        );
      }

      return handler(context.provide<User>(() => user));
    };
  };
}

String? _bearerTokenFrom(Map<String, String> headers) {
  final header = headers['authorization'] ?? headers['Authorization'];
  if (header == null) {
    return null;
  }

  final parts = header.trim().split(RegExp(r'\s+'));
  if (parts.length != 2) {
    return null;
  }

  if (parts.first.toLowerCase() != 'bearer') {
    return null;
  }

  return parts.last;
}
