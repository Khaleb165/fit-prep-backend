import 'package:bcrypt/bcrypt.dart';

abstract class PasswordHasher {
  String hash(String password);
  bool verify(String password, String passwordHash);
}

class BCryptPasswordHasher implements PasswordHasher {
  const BCryptPasswordHasher({
    this.logRounds = 12,
  });

  final int logRounds;

  @override
  String hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: logRounds));
  }

  @override
  bool verify(String password, String passwordHash) {
    return BCrypt.checkpw(password, passwordHash);
  }
}
