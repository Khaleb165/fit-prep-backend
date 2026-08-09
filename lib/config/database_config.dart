import 'package:fit_prep_backend/config/environment.dart';

class DatabaseConfig {
  const DatabaseConfig({
    required this.databaseUrl,
    required this.autoMigrate,
  });

  factory DatabaseConfig.fromEnvironment({Environment? environment}) {
    final env = environment ?? Environment.current();

    return DatabaseConfig(
      databaseUrl: env.get('DATABASE_URL_PROD'),
      autoMigrate: env.getBool('DATABASE_AUTO_MIGRATE'),
    );
  }

  final String? databaseUrl;
  final bool autoMigrate;

  bool get isConfigured => databaseUrl != null;
}
