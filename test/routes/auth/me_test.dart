import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/auth_controller.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/me/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  test('GET /auth/me returns the authenticated user', () async {
    final context = _MockRequestContext();
    final user = User(
      id: 'user-id',
      username: 'caleb',
      email: 'caleb@example.com',
      passwordHash: 'hash',
      timezone: 'Africa/Accra',
      createdAt: DateTime.utc(2026),
    );

    when(() => context.request).thenReturn(
      Request.get(Uri.parse('http://localhost/auth/me')),
    );
    when(() => context.read<AuthController>()).thenReturn(
      const AuthController(),
    );
    when(() => context.read<User>()).thenReturn(user);

    final response = route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    final responseUser = body['user'] as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok);
    expect(responseUser['id'], 'user-id');
    expect(responseUser['username'], 'caleb');
    expect(responseUser, isNot(contains('passwordHash')));
  });
}
