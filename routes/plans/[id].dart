import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/plan_controller.dart';

Future<Response> onRequest(RequestContext context, String id) {
  final controller = context.read<PlanController>();
  return controller.resource(context, id);
}
