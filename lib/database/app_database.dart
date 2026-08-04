import 'dart:io';

import 'package:postgres/postgres.dart';

typedef DatabaseSession = TxSession;

class AppDatabase {
  AppDatabase({
    required Pool<dynamic> pool,
    bool autoMigrate = false,
    String schemaPath = 'database/schema.sql',
  }) : _pool = pool,
       _autoMigrate = autoMigrate,
       _schemaPath = schemaPath;

  factory AppDatabase.fromUrl(
    String databaseUrl, {
    bool autoMigrate = false,
  }) {
    return AppDatabase(
      pool: Pool<dynamic>.withUrl(databaseUrl),
      autoMigrate: autoMigrate,
    );
  }

  final Pool<dynamic> _pool;
  final bool _autoMigrate;
  final String _schemaPath;
  Future<void>? _migration;

  Future<Result> execute(
    Sql sql, {
    Map<String, dynamic>? parameters,
    QueryMode? queryMode,
  }) async {
    await _ensureReady();
    return _pool.execute(
      sql,
      parameters: parameters,
      queryMode: queryMode,
    );
  }

  Future<T> runTx<T>(
    Future<T> Function(DatabaseSession session) action,
  ) async {
    await _ensureReady();
    return _pool.runTx<T>(action);
  }

  Future<void> ensureMigrated() {
    return _migration ??= _runMigrations();
  }

  Future<void> close() async {
    await _pool.close();
  }

  Future<void> _ensureReady() async {
    if (_autoMigrate) {
      await ensureMigrated();
    }
  }

  Future<void> _runMigrations() async {
    final schemaFile = File(_schemaPath);
    if (!schemaFile.existsSync()) {
      throw StateError('Database schema file not found at $_schemaPath.');
    }

    await _pool.execute(
      Sql(schemaFile.readAsStringSync()),
      queryMode: QueryMode.simple,
    );
  }
}
