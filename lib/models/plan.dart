class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    this.isChecked = false,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isChecked:
          json['is_checked'] as bool? ?? json['isChecked'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final bool isChecked;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'is_checked': isChecked,
    };
  }
}

class Plan {
  const Plan({
    required this.id,
    required this.userId,
    required this.title,
    required this.items,
    required this.gymSession,
    required this.packingTime,
    required this.reminder,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final List<PlanItem> items;
  final String gymSession;
  final String packingTime;
  final String reminder;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'gym_session': gymSession,
      'packing_time': packingTime,
      'reminder': reminder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Plan copyWith({
    String? id,
    String? userId,
    String? title,
    List<PlanItem>? items,
    String? gymSession,
    String? packingTime,
    String? reminder,
    DateTime? createdAt,
  }) {
    return Plan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      items: items ?? this.items,
      gymSession: gymSession ?? this.gymSession,
      packingTime: packingTime ?? this.packingTime,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
