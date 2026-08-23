class PresetListItem {
  const PresetListItem({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class HealthySnackPreset {
  const HealthySnackPreset({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}

class FitnessPresets {
  const FitnessPresets({
    required this.gymEssentials,
    required this.healthySnacks,
  });

  final List<PresetListItem> gymEssentials;
  final List<HealthySnackPreset> healthySnacks;

  Map<String, Object?> toJson() {
    return {
      'gym_essentials': gymEssentials.map((item) => item.toJson()).toList(),
      'healthy_snacks': healthySnacks.map((item) => item.toJson()).toList(),
    };
  }
}
