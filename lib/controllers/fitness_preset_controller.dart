import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/services/fitness_preset_service.dart';
import 'package:fit_prep_backend/utils/responses.dart';

class FitnessPresetController {
  const FitnessPresetController();

  Response collection(RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return methodNotAllowed(['GET']);
    }

    final presetService = context.read<FitnessPresetService>();
    final presets = presetService.getPresets();

    return Response.json(
      body: {
        'presets': presets.toJson(),
      },
    );
  }
}
