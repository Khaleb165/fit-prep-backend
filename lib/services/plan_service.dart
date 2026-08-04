import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:uuid/uuid.dart';

class PlanService {
  PlanService({
    required PlanRepository planRepository,
    Uuid? uuid,
  }) : _planRepository = planRepository,
       _uuid = uuid ?? const Uuid();

  static const Set<String> gymSessions = {
    'morning',
    'afternoon',
    'evening',
  };
  static const Set<String> reminderOptions = {
    'on_time',
    'one_hour_before',
  };

  final PlanRepository _planRepository;
  final Uuid _uuid;

  Future<Plan> createPlan({
    required User user,
    required String title,
    required List<PlanItem> items,
    required String gymSession,
    required String packingTime,
    required String reminder,
  }) async {
    final plan = Plan(
      id: _uuid.v4(),
      userId: user.id,
      title: _validateTitle(title),
      items: _validateItems(items),
      gymSession: _validateGymSession(gymSession),
      packingTime: _validatePackingTime(packingTime),
      reminder: _validateReminder(reminder),
      createdAt: DateTime.now().toUtc(),
    );

    return _planRepository.create(plan);
  }

  Future<List<Plan>> listPlans(User user) {
    return _planRepository.listByUserId(user.id);
  }

  Future<Plan> getPlan({
    required User user,
    required String planId,
  }) async {
    final plan = await _planRepository.findByIdForUser(
      id: planId,
      userId: user.id,
    );

    if (plan == null) {
      throw const PlanServiceException(
        code: PlanErrorCode.notFound,
        message: 'Plan not found.',
      );
    }

    return plan;
  }

  Future<Plan> updatePlan({
    required User user,
    required String planId,
    required String title,
    required List<PlanItem> items,
    required String gymSession,
    required String packingTime,
    required String reminder,
  }) async {
    final existingPlan = await getPlan(user: user, planId: planId);
    final updatedPlan = existingPlan.copyWith(
      title: _validateTitle(title),
      items: _validateItems(items),
      gymSession: _validateGymSession(gymSession),
      packingTime: _validatePackingTime(packingTime),
      reminder: _validateReminder(reminder),
    );

    return _planRepository.update(updatedPlan);
  }

  Future<void> deletePlan({
    required User user,
    required String planId,
  }) async {
    final deleted = await _planRepository.deleteForUser(
      id: planId,
      userId: user.id,
    );

    if (!deleted) {
      throw const PlanServiceException(
        code: PlanErrorCode.notFound,
        message: 'Plan not found.',
      );
    }
  }

  String _validateTitle(String title) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'Plan title is required.',
      );
    }

    return normalizedTitle;
  }

  List<PlanItem> _validateItems(List<PlanItem> items) {
    if (items.isEmpty) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'At least one checklist item is required.',
      );
    }

    final itemIds = <String>{};
    for (final item in items) {
      final itemId = item.id.trim();
      if (itemId.isEmpty) {
        throw const PlanServiceException(
          code: PlanErrorCode.validation,
          message: 'Checklist item id is required.',
        );
      }
      if (item.title.trim().isEmpty) {
        throw const PlanServiceException(
          code: PlanErrorCode.validation,
          message: 'Checklist item title is required.',
        );
      }
      if (!itemIds.add(itemId)) {
        throw const PlanServiceException(
          code: PlanErrorCode.validation,
          message: 'Checklist item ids must be unique within a plan.',
        );
      }
    }

    return items
        .map(
          (item) => PlanItem(
            id: item.id.trim(),
            title: item.title.trim(),
            isChecked: item.isChecked,
          ),
        )
        .toList();
  }

  String _validateGymSession(String gymSession) {
    final normalizedGymSession = gymSession.trim().toLowerCase();
    if (!gymSessions.contains(normalizedGymSession)) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'Gym session must be morning, afternoon, or evening.',
      );
    }

    return normalizedGymSession;
  }

  String _validatePackingTime(String packingTime) {
    final normalizedPackingTime = packingTime.trim();
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(
      normalizedPackingTime,
    );
    if (match == null) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'Packing time must use HH:mm format.',
      );
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'Packing time must be a valid 24-hour time.',
      );
    }

    return normalizedPackingTime;
  }

  String _validateReminder(String reminder) {
    final normalizedReminder = reminder.trim().toLowerCase();
    if (!reminderOptions.contains(normalizedReminder)) {
      throw const PlanServiceException(
        code: PlanErrorCode.validation,
        message: 'Reminder must be on_time or one_hour_before.',
      );
    }

    return normalizedReminder;
  }
}

class PlanServiceException implements Exception {
  const PlanServiceException({
    required this.code,
    required this.message,
  });

  final PlanErrorCode code;
  final String message;
}

enum PlanErrorCode {
  validation,
  notFound,
}
