import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/auth_controller.dart';
import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/utils/hashing.dart';
import 'package:fit_prep_backend/utils/jwt.dart';

final UserRepository _userRepository = InMemoryUserRepository();
final JwtService _jwtService = JwtService(
  config: JwtConfig.fromEnvironment(),
);
final AuthService _authService = AuthService(
  userRepository: _userRepository,
  passwordHasher: const BCryptPasswordHasher(),
  jwtService: _jwtService,
);

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<UserRepository>((context) => _userRepository))
      .use(provider<JwtService>((context) => _jwtService))
      .use(provider<AuthService>((context) => _authService))
      .use(provider<AuthController>((context) => const AuthController()));
}
