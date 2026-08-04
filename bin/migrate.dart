import 'package:fit_prep_backend/config/database_config.dart';
import 'package:fit_prep_backend/database/app_database.dart';

Future<void> main() async {
  final config = DatabaseConfig.fromEnvironment();
  final databaseUrl = config.databaseUrl;
  if (databaseUrl == null) {
    throw StateError('DATABASE_URL is required to run migrations.');
  }

  final database = AppDatabase.fromUrl(databaseUrl);
  try {
    await database.ensureMigrated();
    // ignore: avoid_print
    print('Database schema is ready.');
  } finally {
    await database.close();
  }
}
