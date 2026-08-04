import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/config/database_config.dart';
import 'package:fit_prep_backend/controllers/auth_controller.dart';
import 'package:fit_prep_backend/controllers/plan_controller.dart';
import 'package:fit_prep_backend/database/app_database.dart';
import 'package:fit_prep_backend/middleware/cors_middleware.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:fit_prep_backend/repositories/postgres_plan_repository.dart';
import 'package:fit_prep_backend/repositories/postgres_user_repository.dart';
import 'package:fit_prep_backend/repositories/user_repository.dart';
import 'package:fit_prep_backend/services/auth_service.dart';
import 'package:fit_prep_backend/services/plan_service.dart';
import 'package:fit_prep_backend/utils/hashing.dart';
import 'package:fit_prep_backend/utils/jwt.dart';

final DatabaseConfig _databaseConfig = DatabaseConfig.fromEnvironment();
final AppDatabase? _database = _databaseConfig.isConfigured
    ? AppDatabase.fromUrl(
        _databaseConfig.databaseUrl!,
        autoMigrate: _databaseConfig.autoMigrate,
      )
    : null;
final UserRepository _userRepository = _createUserRepository(_database);
final PlanRepository _planRepository = _createPlanRepository(_database);
final JwtService _jwtService = JwtService(
  config: JwtConfig.fromEnvironment(),
);
final AuthService _authService = AuthService(
  userRepository: _userRepository,
  passwordHasher: const BCryptPasswordHasher(),
  jwtService: _jwtService,
);
final PlanService _planService = PlanService(
  planRepository: _planRepository,
);

Handler middleware(Handler handler) {
  return handler
      .use(cors())
      .use(requestLogger())
      .use(provider<UserRepository>((context) => _userRepository))
      .use(provider<JwtService>((context) => _jwtService))
      .use(provider<AuthService>((context) => _authService))
      .use(provider<PlanRepository>((context) => _planRepository))
      .use(provider<PlanService>((context) => _planService))
      .use(provider<AuthController>((context) => const AuthController()))
      .use(provider<PlanController>((context) => const PlanController()));
}

UserRepository _createUserRepository(AppDatabase? database) {
  if (database == null) {
    return InMemoryUserRepository();
  }

  return PostgresUserRepository(database: database);
}

PlanRepository _createPlanRepository(AppDatabase? database) {
  if (database == null) {
    return InMemoryPlanRepository();
  }

  return PostgresPlanRepository(database: database);
}
