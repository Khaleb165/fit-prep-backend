import 'package:fit_prep_backend/database/app_database.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:postgres/postgres.dart';

class PostgresUserRepository implements UserRepository {
  const PostgresUserRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  @override
  Future<User> create(User user) async {
    try {
      await _database.execute(
        Sql.named('''
INSERT INTO users (
  id,
  username,
  email,
  password_hash,
  name,
  timezone,
  created_at
) VALUES (
  @id,
  @username,
  @email,
  @password_hash,
  @name,
  @timezone,
  @created_at
)
'''),
        parameters: <String, dynamic>{
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'password_hash': user.passwordHash,
          'name': user.name,
          'timezone': user.timezone,
          'created_at': user.createdAt.toUtc(),
        },
      );
    } on ServerException catch (error) {
      if (error.code == '23505') {
        throw const UserRepositoryException(
          'Email or username is already registered.',
        );
      }

      rethrow;
    }

    return user;
  }

  @override
  Future<User?> findByEmail(String email) {
    return _findOne(
      whereClause: 'lower(email) = lower(@value)',
      value: email,
    );
  }

  @override
  Future<User?> findById(String id) {
    return _findOne(
      whereClause: 'id = @value',
      value: id,
    );
  }

  @override
  Future<User?> findByUsername(String username) {
    return _findOne(
      whereClause: 'lower(username) = lower(@value)',
      value: username,
    );
  }

  @override
  Future<void> clear() async {
    await _database.execute(Sql('DELETE FROM users'));
  }

  Future<User?> _findOne({
    required String whereClause,
    required String value,
  }) async {
    final result = await _database.execute(
      Sql.named('''
SELECT id, username, email, password_hash, name, timezone, created_at
FROM users
WHERE $whereClause
LIMIT 1
'''),
      parameters: <String, dynamic>{
        'value': value,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return _userFromRow(result.first.toColumnMap());
  }

  User _userFromRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] as String,
      username: row['username'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      name: row['name'] as String?,
      timezone: row['timezone'] as String,
      createdAt: (row['created_at'] as DateTime).toUtc(),
    );
  }
}
