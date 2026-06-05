import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/auth_controller.dart';

Response onRequest(RequestContext context) {
  final controller = context.read<AuthController>();
  return controller.me(context);
}
