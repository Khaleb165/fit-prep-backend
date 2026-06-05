import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/utils/hashing.dart';
import 'package:fit_prep_backend/utils/jwt.dart';
import 'package:test/test.dart';

void main() {
  late UserRepository userRepository;
  late AuthService authService;

  setUp(() {
    userRepository = InMemoryUserRepository();
    authService = AuthService(
      userRepository: userRepository,
      passwordHasher: const BCryptPasswordHasher(logRounds: 4),
      jwtService: const JwtService(
        config: JwtConfig(secret: 'test-secret'),
      ),
    );
  });

  test('register creates a user with a hashed password and token', () async {
    final result = await authService.register(
      username: 'caleb',
      email: 'caleb@example.com',
      password: 'secret1',
      name: 'Caleb',
      timezone: 'Africa/Accra',
    );

    final storedUser = await userRepository.findByUsername('caleb');

    expect(result.token, isNotEmpty);
    expect(result.expiresInSeconds, 604800);
    expect(storedUser, isNotNull);
    expect(storedUser!.passwordHash, isNot('secret1'));
    expect(storedUser.timezone, 'Africa/Accra');
  });

  test('login returns a token for valid credentials', () async {
    await authService.register(
      username: 'caleb',
      email: 'caleb@example.com',
      password: 'secret1',
    );

    final result = await authService.login(
      username: 'caleb',
      password: 'secret1',
    );

    expect(result.token, isNotEmpty);
    expect(result.user.username, 'caleb');
  });

  test('register rejects duplicate usernames', () async {
    await authService.register(
      username: 'caleb',
      email: 'caleb@example.com',
      password: 'secret1',
    );

    expect(
      () => authService.register(
        username: 'Caleb',
        email: 'other@example.com',
        password: 'secret1',
      ),
      throwsA(isA<AuthServiceException>()),
    );
  });

  test('userFromToken returns the matching user', () async {
    final result = await authService.register(
      username: 'caleb',
      email: 'caleb@example.com',
      password: 'secret1',
    );

    final user = await authService.userFromToken(result.token);

    expect(user, isNotNull);
    expect(user!.id, result.user.id);
  });
}
