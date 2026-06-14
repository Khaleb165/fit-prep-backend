import 'package:fit_prep_backend/models/plan.dart';

abstract class PlanRepository {
  Future<Plan> create(Plan plan);
  Future<List<Plan>> listByUserId(String userId);
  Future<Plan?> findByIdForUser({
    required String id,
    required String userId,
  });
  Future<Plan> update(Plan plan);
  Future<bool> deleteForUser({
    required String id,
    required String userId,
  });
  Future<void> clear();
}

class InMemoryPlanRepository implements PlanRepository {
  final Map<String, Plan> _plansById = <String, Plan>{};

  @override
  Future<Plan> create(Plan plan) async {
    _plansById[plan.id] = plan;
    return plan;
  }

  @override
  Future<bool> deleteForUser({
    required String id,
    required String userId,
  }) async {
    final plan = await findByIdForUser(id: id, userId: userId);
    if (plan == null) {
      return false;
    }

    _plansById.remove(id);
    return true;
  }

  @override
  Future<Plan?> findByIdForUser({
    required String id,
    required String userId,
  }) async {
    final plan = _plansById[id];
    if (plan == null || plan.userId != userId) {
      return null;
    }

    return plan;
  }

  @override
  Future<List<Plan>> listByUserId(String userId) async {
    final plans =
        _plansById.values.where((plan) => plan.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return plans;
  }

  @override
  Future<Plan> update(Plan plan) async {
    _plansById[plan.id] = plan;
    return plan;
  }

  @override
  Future<void> clear() async {
    _plansById.clear();
  }
}
