import 'package:fit_prep_backend/models/fitness_presets.dart';

class FitnessPresetService {
  const FitnessPresetService();

  FitnessPresets getPresets() {
    return const FitnessPresets(
      gymEssentials: [
        PresetListItem(id: 'water-bottle', title: 'Water bottle'),
        PresetListItem(id: 'gym-towel', title: 'Gym towel'),
        PresetListItem(id: 'workout-gloves', title: 'Workout gloves'),
        PresetListItem(id: 'training-shoes', title: 'Training shoes'),
        PresetListItem(id: 'underwear-and-socks', title: 'Underwear and socks'),
        PresetListItem(
          id: 'deodorant-or-body-spray',
          title: 'Deodorant or body spray',
        ),
        PresetListItem(id: 'soap-and-sponge', title: 'Soap and sponge'),
        PresetListItem(
          id: 'comfortable-workout-clothes',
          title: 'Comfortable workout clothes',
        ),
        PresetListItem(
          id: 'headphones-or-earbuds',
          title: 'Headphones or earbuds',
        ),
      ],
      healthySnacks: [
        HealthySnackPreset(
          id: 'greek-yogurt-with-berries',
          title: 'Greek yogurt with berries',
          description:
              'Great before or after the gym because it combines '
              'quick carbs with protein to support energy and recovery.',
        ),
        HealthySnackPreset(
          id: 'banana-with-peanut-butter',
          title: 'Banana with peanut butter',
          description:
              'A strong pre-workout option since the banana gives '
              'fast fuel and the peanut butter helps keep you satisfied for '
              'longer.',
        ),
        HealthySnackPreset(
          id: 'trail-mix-with-nuts-and-seeds',
          title: 'Trail mix with nuts and seeds',
          description:
              'Helpful after training or between sessions when you '
              'want portable energy, healthy fats, and a little protein.',
        ),
        HealthySnackPreset(
          id: 'apple-slices-with-almond-butter',
          title: 'Apple slices with almond butter',
          description:
              'A light snack before the gym that gives you natural '
              'carbs for fuel and a bit of fat to steady your energy.',
        ),
        HealthySnackPreset(
          id: 'protein-bar-with-low-added-sugar',
          title: 'Protein bar with low added sugar',
          description:
              'Convenient after a workout when you want an easy '
              'protein boost to help support muscle repair.',
        ),
        HealthySnackPreset(
          id: 'boiled-eggs-and-whole-grain-crackers',
          title: 'Boiled eggs and whole-grain crackers',
          description:
              'Best after the gym because the eggs offer protein '
              'while the crackers help top up energy stores.',
        ),
      ],
    );
  }
}
