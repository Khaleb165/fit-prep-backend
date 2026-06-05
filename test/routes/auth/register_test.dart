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

import '../../../routes/auth/register.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late AuthService authService;
  late _MockRequestContext context;

  setUp(() {
    authService = AuthService(
      userRepository: InMemoryUserRepository(),
      passwordHasher: const BCryptPasswordHasher(logRounds: 4),
      jwtService: const JwtService(
        config: JwtConfig(secret: 'test-secret'),
      ),
    );
    context = _MockRequestContext();
    when(() => context.read<AuthController>()).thenReturn(
      const AuthController(),
    );
    when(() => context.read<AuthService>()).thenReturn(authService);
  });

  test('POST /auth/register creates a user and token', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/auth/register'),
        headers: {'content-type': ContentType.json.value},
        body: jsonEncode({
          'username': 'caleb',
          'email': 'caleb@example.com',
          'password': 'secret1',
          'name': 'Caleb',
          'timezone': 'Africa/Accra',
        }),
      ),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.created);
    expect(body['token'], isA<String>());
    expect(body['expires_in'], 604800);
    expect(user['username'], 'caleb');
    expect(user['email'], 'caleb@example.com');
    expect(user, isNot(contains('passwordHash')));
  });

  test('POST /auth/register validates email', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/auth/register'),
        headers: {'content-type': ContentType.json.value},
        body: jsonEncode({
          'username': 'caleb',
          'email': 'not-an-email',
          'password': 'secret1',
        }),
      ),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.badRequest);
    expect(body['error'], 'Enter a valid email address.');
  });
}
