import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/fitness_preset_controller.dart';
import 'package:fit_prep_backend/services/fitness_preset_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/presets/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /presets', () {
    late RequestContext context;
    late Request request;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => context.read<FitnessPresetController>()).thenReturn(
        const FitnessPresetController(),
      );
      when(() => context.read<FitnessPresetService>()).thenReturn(
        const FitnessPresetService(),
      );
    });

    test(
      'responds with 405 Method Not Allowed when method is not GET',
      () async {
        when(() => request.method).thenReturn(HttpMethod.post);
        final response = route.onRequest(context);
        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );

    test('responds with a 200 and presets payload', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      final response = route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final json = await response.json() as Map<String, dynamic>;
      final presets = json['presets'] as Map<String, dynamic>;

      expect(json.containsKey('presets'), isTrue);
      expect(presets.containsKey('gym_essentials'), isTrue);
      expect(presets['gym_essentials'], isA<List<dynamic>>());
      expect((presets['gym_essentials'] as List).length, greaterThan(0));

      final firstEssential = (presets['gym_essentials'] as List).first as Map;
      expect(firstEssential['id'], isA<String>());
      expect(firstEssential['title'], isA<String>());

      expect(presets.containsKey('healthy_snacks'), isTrue);
      expect(presets['healthy_snacks'], isA<List<dynamic>>());
      expect((presets['healthy_snacks'] as List).length, greaterThan(0));

      final firstSnack = (presets['healthy_snacks'] as List).first as Map;
      expect(firstSnack['id'], isA<String>());
      expect(firstSnack['title'], isA<String>());
      expect(firstSnack['description'], isA<String>());
    });
  });
}
