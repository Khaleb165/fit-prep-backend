import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/middleware/auth_middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(requireAuthentication());
}
