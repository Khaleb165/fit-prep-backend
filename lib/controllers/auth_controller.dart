import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/utils/request_body.dart';
import 'package:fit_prep_backend/utils/responses.dart';

class AuthController {
  const AuthController();

  Future<Response> register(RequestContext context) async {
    if (context.request.method != HttpMethod.post) {
      return methodNotAllowed(['POST']);
    }

    final authService = context.read<AuthService>();

    try {
      final body = await readJsonObject(context);
      final result = await authService.register(
        username: _stringValue(body, 'username'),
        email: _stringValue(body, 'email'),
        password: _stringValue(body, 'password'),
        name: _nullableStringValue(body, 'name'),
        timezone: _nullableStringValue(body, 'timezone'),
      );

      return Response.json(
        statusCode: HttpStatus.created,
        body: _authBody(
          message: 'User registered successfully.',
          result: result,
        ),
      );
    } on FormatException {
      return jsonError(
        message: 'Request body must be a JSON object.',
        statusCode: HttpStatus.badRequest,
      );
    } on AuthServiceException catch (error) {
      return jsonError(
        message: error.message,
        statusCode: _statusCodeFor(error.code),
      );
    }
  }

  Future<Response> login(RequestContext context) async {
    if (context.request.method != HttpMethod.post) {
      return methodNotAllowed(['POST']);
    }

    final authService = context.read<AuthService>();

    try {
      final body = await readJsonObject(context);
      final result = await authService.login(
        username: _stringValue(body, 'username'),
        password: _stringValue(body, 'password'),
      );

      return Response.json(
        body: _authBody(
          message: 'User logged in successfully.',
          result: result,
        ),
      );
    } on FormatException {
      return jsonError(
        message: 'Request body must be a JSON object.',
        statusCode: HttpStatus.badRequest,
      );
    } on AuthServiceException catch (error) {
      return jsonError(
        message: error.message,
        statusCode: _statusCodeFor(error.code),
      );
    }
  }

  Response me(RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return methodNotAllowed(['GET']);
    }

    final user = context.read<User>();
    return Response.json(body: {'user': user.toJson()});
  }

  Map<String, Object?> _authBody({
    required String message,
    required AuthResult result,
  }) {
    return {
      'message': message,
      'user': result.user.toJson(),
      'token': result.token,
      'token_type': 'Bearer',
      'expires_in': result.expiresInSeconds,
    };
  }

  String _stringValue(Map<String, dynamic> body, String key) {
    return body[key]?.toString() ?? '';
  }

  String? _nullableStringValue(Map<String, dynamic> body, String key) {
    return body[key]?.toString();
  }

  int _statusCodeFor(AuthErrorCode code) {
    return switch (code) {
      AuthErrorCode.validation => HttpStatus.badRequest,
      AuthErrorCode.conflict => HttpStatus.conflict,
      AuthErrorCode.unauthorized => HttpStatus.unauthorized,
    };
  }
}
