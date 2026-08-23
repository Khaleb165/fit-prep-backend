import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/fitness_preset_controller.dart';

Response onRequest(RequestContext context) {
  final controller = context.read<FitnessPresetController>();
  return controller.collection(context);
}
