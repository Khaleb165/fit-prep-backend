import 'package:fit_prep_backend/services/fitness_preset_service.dart';
import 'package:test/test.dart';

void main() {
  group('FitnessPresetService', () {
    test('returns named gym essentials and healthy snacks', () {
      const service = FitnessPresetService();
      final presets = service.getPresets();

      expect(presets.gymEssentials, isNotEmpty);
      expect(presets.gymEssentials.first.id, 'water-bottle');
      expect(presets.gymEssentials.first.title, 'Water bottle');

      expect(presets.healthySnacks, isNotEmpty);
      expect(presets.healthySnacks.first.id, 'greek-yogurt-with-berries');
      expect(presets.healthySnacks.first.title, 'Greek yogurt with berries');
      expect(presets.healthySnacks.first.description, isNotEmpty);
    });
  });
}
