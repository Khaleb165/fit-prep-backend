import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:fit_prep_backend/services/plan_service.dart';
import 'package:test/test.dart';

void main() {
  final user = User(
    id: 'user-1',
    username: 'caleb',
    email: 'caleb@example.com',
    passwordHash: 'hash',
    timezone: 'Africa/Accra',
    createdAt: DateTime(2026),
  );
  final otherUser = User(
    id: 'user-2',
    username: 'ama',
    email: 'ama@example.com',
    passwordHash: 'hash',
    timezone: 'Africa/Accra',
    createdAt: DateTime(2026),
  );
  const items = <PlanItem>[
    PlanItem(id: 'item-1', title: 'Water bottle'),
    PlanItem(id: 'item-2', title: 'Gym towel', isChecked: true),
  ];

  late PlanService planService;

  setUp(() {
    planService = PlanService(
      planRepository: InMemoryPlanRepository(),
    );
  });

  test('creates and lists full plans for a user', () async {
    final plan = await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '07:30',
      reminder: 'one_hour_before',
    );

    final plans = await planService.listPlans(user);

    expect(plan.title, 'Morning Workout Plan');
    expect(plan.items, hasLength(2));
    expect(plan.gymSession, 'morning');
    expect(plan.packingTime, '07:30');
    expect(plan.reminderTime, '06:30');
    expect(plan.reminder, 'one_hour_before');
    expect(plans, hasLength(1));
    expect(plans.first.id, plan.id);
  });

  test('does not return plans across users', () async {
    await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '07:30',
      reminder: 'one_hour_before',
    );

    final plans = await planService.listPlans(otherUser);

    expect(plans, isEmpty);
  });

  test('updates full plan details', () async {
    final plan = await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '07:30',
      reminder: 'one_hour_before',
    );

    final updatedPlan = await planService.updatePlan(
      user: user,
      planId: plan.id,
      title: 'Evening Workout Plan',
      items: const <PlanItem>[PlanItem(id: 'item-3', title: 'Shoes')],
      gymSession: 'evening',
      packingTime: '18:45',
      reminder: 'on_time',
    );

    expect(updatedPlan.title, 'Evening Workout Plan');
    expect(updatedPlan.items.single.title, 'Shoes');
    expect(updatedPlan.gymSession, 'evening');
    expect(updatedPlan.packingTime, '18:45');
    expect(updatedPlan.reminder, 'on_time');
  });

  test('rejects invalid reminder details', () async {
    expect(
      () => planService.createPlan(
        user: user,
        title: 'Morning Workout Plan',
        items: items,
        gymSession: 'night',
        packingTime: '07:30',
        reminder: 'one_hour_before',
      ),
      throwsA(isA<PlanServiceException>()),
    );
  });

  test('derives reminder time across midnight', () async {
    final plan = await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '00:15',
      reminder: 'one_hour_before',
    );

    expect(plan.reminderTime, '23:15');
  });

  test('rejects missing and duplicate checklist item ids', () async {
    for (final invalidItems in <List<PlanItem>>[
      const <PlanItem>[PlanItem(id: '', title: 'Shoes')],
      const <PlanItem>[
        PlanItem(id: 'same-id', title: 'Shoes'),
        PlanItem(id: 'same-id', title: 'Towel'),
      ],
    ]) {
      expect(
        () => planService.createPlan(
          user: user,
          title: 'Morning Workout Plan',
          items: invalidItems,
          gymSession: 'morning',
          packingTime: '07:30',
          reminder: 'on_time',
        ),
        throwsA(isA<PlanServiceException>()),
      );
    }
  });

  test('deletes a plan', () async {
    final plan = await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '07:30',
      reminder: 'one_hour_before',
    );

    await planService.deletePlan(user: user, planId: plan.id);

    expect(await planService.listPlans(user), isEmpty);
  });

  test('throws for missing plan', () async {
    expect(
      () => planService.deletePlan(user: user, planId: 'missing-plan'),
      throwsA(isA<PlanServiceException>()),
    );
  });
}
