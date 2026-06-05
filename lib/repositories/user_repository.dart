import 'package:fit_prep_backend/models/user.dart';

abstract class UserRepository {
  Future<User> create(User user);
  Future<User?> findById(String id);
  Future<User?> findByEmail(String email);
  Future<User?> findByUsername(String username);
  Future<void> clear();
}

class InMemoryUserRepository implements UserRepository {
  final Map<String, User> _usersById = <String, User>{};
  final Map<String, String> _idsByEmail = <String, String>{};
  final Map<String, String> _idsByUsername = <String, String>{};

  @override
  Future<User> create(User user) async {
    final emailKey = _normalize(user.email);
    final usernameKey = _normalize(user.username);

    if (_idsByEmail.containsKey(emailKey)) {
      throw const UserRepositoryException('Email is already registered.');
    }

    if (_idsByUsername.containsKey(usernameKey)) {
      throw const UserRepositoryException('Username is already taken.');
    }

    _usersById[user.id] = user;
    _idsByEmail[emailKey] = user.id;
    _idsByUsername[usernameKey] = user.id;
    return user;
  }

  @override
  Future<User?> findByEmail(String email) async {
    final id = _idsByEmail[_normalize(email)];
    if (id == null) {
      return null;
    }

    return _usersById[id];
  }

  @override
  Future<User?> findById(String id) async {
    return _usersById[id];
  }

  @override
  Future<User?> findByUsername(String username) async {
    final id = _idsByUsername[_normalize(username)];
    if (id == null) {
      return null;
    }

    return _usersById[id];
  }

  @override
  Future<void> clear() async {
    _usersById.clear();
    _idsByEmail.clear();
    _idsByUsername.clear();
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class UserRepositoryException implements Exception {
  const UserRepositoryException(this.message);

  final String message;
}
