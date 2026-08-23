import 'package:fit_prep_backend/database/app_database.dart';
import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:postgres/postgres.dart';

class PostgresPlanRepository implements PlanRepository {
  const PostgresPlanRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  @override
  Future<Plan> create(Plan plan) async {
    await _database.runTx((session) async {
      await _insertPlan(session, plan);
      await _insertItems(session, plan);
    });

    return plan;
  }

  @override
  Future<bool> deleteForUser({
    required String id,
    required String userId,
  }) async {
    final result = await _database.execute(
      Sql.named('''
DELETE FROM plans
WHERE id = @id AND user_id = @user_id
'''),
      parameters: <String, dynamic>{
        'id': id,
        'user_id': userId,
      },
    );

    return result.affectedRows > 0;
  }

  @override
  Future<Plan?> findByIdForUser({
    required String id,
    required String userId,
  }) async {
    final plans = await _fetchPlans(
      whereClause: 'plans.id = @id AND plans.user_id = @user_id',
      parameters: <String, dynamic>{
        'id': id,
        'user_id': userId,
      },
    );

    if (plans.isEmpty) {
      return null;
    }

    return plans.first;
  }

  @override
  Future<List<Plan>> listByUserId(String userId) {
    return _fetchPlans(
      whereClause: 'plans.user_id = @user_id',
      parameters: <String, dynamic>{
        'user_id': userId,
      },
    );
  }

  @override
  Future<Plan> update(Plan plan) async {
    await _database.runTx((session) async {
      await session.execute(
        Sql.named('''
UPDATE plans
SET title = @title,
    gym_session = @gym_session,
    packing_time = @packing_time,
    reminder = @reminder,
    last_checklist_reset_key = @last_checklist_reset_key
WHERE id = @id AND user_id = @user_id
'''),
        parameters: _updatePlanParameters(plan),
      );

      await session.execute(
        Sql.named('DELETE FROM plan_items WHERE plan_id = @plan_id'),
        parameters: <String, dynamic>{
          'plan_id': plan.id,
        },
      );

      await _insertItems(session, plan);
    });

    return plan;
  }

  @override
  Future<void> clear() async {
    await _database.execute(Sql('DELETE FROM plans'));
  }

  Future<void> _insertPlan(DatabaseSession session, Plan plan) async {
    await session.execute(
      Sql.named('''
INSERT INTO plans (
  id,
  user_id,
  title,
  gym_session,
  packing_time,
  reminder,
  created_at,
  last_checklist_reset_key
) VALUES (
  @id,
  @user_id,
  @title,
  @gym_session,
  @packing_time,
  @reminder,
  @created_at,
  @last_checklist_reset_key
)
'''),
      parameters: _planParameters(plan),
    );
  }

  Future<void> _insertItems(DatabaseSession session, Plan plan) async {
    for (var index = 0; index < plan.items.length; index++) {
      final item = plan.items[index];
      await session.execute(
        Sql.named('''
INSERT INTO plan_items (
  plan_id,
  id,
  title,
  is_checked,
  sort_order
) VALUES (
  @plan_id,
  @id,
  @title,
  @is_checked,
  @sort_order
)
'''),
        parameters: <String, dynamic>{
          'plan_id': plan.id,
          'id': item.id,
          'title': item.title,
          'is_checked': item.isChecked,
          'sort_order': index,
        },
      );
    }
  }

  Future<List<Plan>> _fetchPlans({
    required String whereClause,
    required Map<String, dynamic> parameters,
  }) async {
    final result = await _database.execute(
      Sql.named('''
SELECT
  plans.id,
  plans.user_id,
  plans.title,
  plans.gym_session,
  plans.packing_time,
  plans.reminder,
  plans.created_at,
  plans.last_checklist_reset_key,
  plan_items.id AS item_id,
  plan_items.title AS item_title,
  plan_items.is_checked AS item_is_checked
FROM plans
LEFT JOIN plan_items ON plan_items.plan_id = plans.id
WHERE $whereClause
ORDER BY plans.created_at DESC, plan_items.sort_order ASC
'''),
      parameters: parameters,
    );

    final builders = <String, _PlanBuilder>{};
    for (final row in result) {
      final values = row.toColumnMap();
      final planId = values['id'] as String;
      final builder = builders.putIfAbsent(
        planId,
        () => _PlanBuilder(
          id: planId,
          userId: values['user_id'] as String,
          title: values['title'] as String,
          gymSession: values['gym_session'] as String,
          packingTime: values['packing_time'] as String,
          reminder: values['reminder'] as String,
          createdAt: (values['created_at'] as DateTime).toUtc(),
          lastChecklistResetKey: values['last_checklist_reset_key'] as String?,
        ),
      );

      final itemId = values['item_id'] as String?;
      if (itemId != null) {
        builder.items.add(
          PlanItem(
            id: itemId,
            title: values['item_title'] as String,
            isChecked: values['item_is_checked'] as bool,
          ),
        );
      }
    }

    return builders.values.map((builder) => builder.build()).toList();
  }

  Map<String, dynamic> _planParameters(Plan plan) {
    return <String, dynamic>{
      'id': plan.id,
      'user_id': plan.userId,
      'title': plan.title,
      'gym_session': plan.gymSession,
      'packing_time': plan.packingTime,
      'reminder': plan.reminder,
      'created_at': plan.createdAt.toUtc(),
      'last_checklist_reset_key': plan.lastChecklistResetKey,
    };
  }

  Map<String, dynamic> _updatePlanParameters(Plan plan) {
    return <String, dynamic>{
      'id': plan.id,
      'user_id': plan.userId,
      'title': plan.title,
      'gym_session': plan.gymSession,
      'packing_time': plan.packingTime,
      'reminder': plan.reminder,
      'last_checklist_reset_key': plan.lastChecklistResetKey,
    };
  }
}

class _PlanBuilder {
  _PlanBuilder({
    required this.id,
    required this.userId,
    required this.title,
    required this.gymSession,
    required this.packingTime,
    required this.reminder,
    required this.createdAt,
    this.lastChecklistResetKey,
  });

  final String id;
  final String userId;
  final String title;
  final String gymSession;
  final String packingTime;
  final String reminder;
  final DateTime createdAt;
  final String? lastChecklistResetKey;
  final List<PlanItem> items = <PlanItem>[];

  Plan build() {
    return Plan(
      id: id,
      userId: userId,
      title: title,
      items: items,
      gymSession: gymSession,
      packingTime: packingTime,
      reminder: reminder,
      createdAt: createdAt,
      lastChecklistResetKey: lastChecklistResetKey,
    );
  }
}
