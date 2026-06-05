import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/auth_controller.dart';
import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/utils/hashing.dart';
import 'package:fit_prep_backend/utils/jwt.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/login.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late AuthService authService;
  late _MockRequestContext context;

  setUp(() async {
    authService = AuthService(
      userRepository: InMemoryUserRepository(),
      passwordHasher: const BCryptPasswordHasher(logRounds: 4),
      jwtService: const JwtService(
        config: JwtConfig(secret: 'test-secret'),
      ),
    );
    await authService.register(
      username: 'caleb',
      email: 'caleb@example.com',
      password: 'secret1',
      timezone: 'Africa/Accra',
    );
    context = _MockRequestContext();
    when(() => context.read<AuthController>()).thenReturn(
      const AuthController(),
    );
    when(() => context.read<AuthService>()).thenReturn(authService);
  });

  test('POST /auth/login returns a token', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/auth/login'),
        headers: {'content-type': ContentType.json.value},
        body: jsonEncode({
          'username': 'caleb',
          'password': 'secret1',
        }),
      ),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok);
    expect(body['token'], isA<String>());
    expect(body['token_type'], 'Bearer');
    expect(body['user'], containsPair('username', 'caleb'));
  });

  test('POST /auth/login rejects invalid credentials', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/auth/login'),
        headers: {'content-type': ContentType.json.value},
        body: jsonEncode({
          'username': 'caleb',
          'password': 'wrong-password',
        }),
      ),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(body['error'], 'Invalid username or password.');
  });
}
