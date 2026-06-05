import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:fit_prep_backend/utils/hashing.dart';
import 'package:fit_prep_backend/utils/jwt.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService({
    required UserRepository userRepository,
    required PasswordHasher passwordHasher,
    required JwtService jwtService,
    Uuid? uuid,
  }) : _userRepository = userRepository,
       _passwordHasher = passwordHasher,
       _jwtService = jwtService,
       _uuid = uuid ?? const Uuid();

  final UserRepository _userRepository;
  final PasswordHasher _passwordHasher;
  final JwtService _jwtService;
  final Uuid _uuid;

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? name,
    String? timezone,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = _emptyToNull(name);
    final normalizedTimezone = _emptyToNull(timezone) ?? 'UTC';

    _validateRegisterInput(
      username: normalizedUsername,
      email: normalizedEmail,
      password: password,
    );

    if (await _userRepository.findByUsername(normalizedUsername) != null) {
      throw const AuthServiceException(
        code: AuthErrorCode.conflict,
        message: 'Username is already taken.',
      );
    }

    if (await _userRepository.findByEmail(normalizedEmail) != null) {
      throw const AuthServiceException(
        code: AuthErrorCode.conflict,
        message: 'Email is already registered.',
      );
    }

    final passwordHash = _passwordHasher.hash(password);
    final user = await _userRepository.create(
      User(
        id: _uuid.v4(),
        username: normalizedUsername,
        email: normalizedEmail,
        passwordHash: passwordHash,
        name: normalizedName,
        timezone: normalizedTimezone,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    return _authResultFor(user);
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        code: AuthErrorCode.validation,
        message: 'Username and password are required.',
      );
    }

    final user = await _userRepository.findByUsername(normalizedUsername);
    if (user == null || !_passwordHasher.verify(password, user.passwordHash)) {
      throw const AuthServiceException(
        code: AuthErrorCode.unauthorized,
        message: 'Invalid username or password.',
      );
    }

    return _authResultFor(user);
  }

  Future<User?> userFromToken(String token) async {
    final claims = _jwtService.verify(token);
    if (claims == null) {
      return null;
    }

    return _userRepository.findById(claims.userId);
  }

  AuthResult _authResultFor(User user) {
    return AuthResult(
      user: user,
      token: _jwtService.createToken(user),
      expiresInSeconds: _jwtService.expiresIn.inSeconds,
    );
  }

  void _validateRegisterInput({
    required String username,
    required String email,
    required String password,
  }) {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        code: AuthErrorCode.validation,
        message: 'Username, email, and password are required.',
      );
    }

    if (username.length < 3) {
      throw const AuthServiceException(
        code: AuthErrorCode.validation,
        message: 'Username must be at least 3 characters.',
      );
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      throw const AuthServiceException(
        code: AuthErrorCode.validation,
        message: 'Enter a valid email address.',
      );
    }

    if (password.length < 6) {
      throw const AuthServiceException(
        code: AuthErrorCode.validation,
        message: 'Password must be at least 6 characters.',
      );
    }
  }

  String? _emptyToNull(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue;
  }
}

class AuthResult {
  const AuthResult({
    required this.user,
    required this.token,
    required this.expiresInSeconds,
  });

  final User user;
  final String token;
  final int expiresInSeconds;
}

class AuthServiceException implements Exception {
  const AuthServiceException({
    required this.code,
    required this.message,
  });

  final AuthErrorCode code;
  final String message;
}

enum AuthErrorCode {
  validation,
  conflict,
  unauthorized,
}
