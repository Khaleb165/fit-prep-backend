import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:fit_prep_backend/models/user.dart';

class JwtConfig {
  const JwtConfig({
    required this.secret,
    this.issuer = 'fit_prep_backend',
    this.expiresIn = const Duration(days: 7),
  });

  factory JwtConfig.fromEnvironment() {
    return JwtConfig(
      secret:
          Platform.environment['JWT_SECRET'] ??
          'fit-prep-local-development-secret-change-me',
    );
  }

  final String secret;
  final String issuer;
  final Duration expiresIn;
}

class JwtService {
  const JwtService({
    required JwtConfig config,
  }) : _config = config;

  final JwtConfig _config;

  Duration get expiresIn => _config.expiresIn;

  String createToken(User user) {
    final jwt = JWT(
      {
        'email': user.email,
        'username': user.username,
      },
      issuer: _config.issuer,
      subject: user.id,
    );

    return jwt.sign(
      SecretKey(_config.secret),
      expiresIn: _config.expiresIn,
    );
  }

  JwtClaims? verify(String token) {
    try {
      final jwt = JWT.verify(
        token,
        SecretKey(_config.secret),
        issuer: _config.issuer,
      );
      final payload = jwt.payload;
      if (payload is! Map) {
        return null;
      }

      final claims = Map<String, dynamic>.from(payload);
      final userId = jwt.subject ?? claims['sub']?.toString();
      final email = claims['email']?.toString();
      final username = claims['username']?.toString();

      if (userId == null || email == null || username == null) {
        return null;
      }

      return JwtClaims(
        userId: userId,
        email: email,
        username: username,
      );
    } on JWTException {
      return null;
    }
  }
}

class JwtClaims {
  const JwtClaims({
    required this.userId,
    required this.email,
    required this.username,
  });

  final String userId;
  final String email;
  final String username;
}
