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

  group('daily checklist reset', () {
    late DateTime now;
    late PlanService clockedPlanService;
    late User accraUser;

    setUp(() {
      now = DateTime.utc(2026, 8, 14, 2);
      clockedPlanService = PlanService(
        planRepository: InMemoryPlanRepository(),
        clock: () => now,
      );
      accraUser = User(
        id: 'user-clock',
        username: 'clock',
        email: 'clock@example.com',
        passwordHash: 'hash',
        timezone: 'Africa/Accra',
        createdAt: DateTime.utc(2026),
      );
    });

    test('clears checked items after the reset boundary', () async {
      await _createPlan(clockedPlanService, accraUser);

      final plans = await clockedPlanService.listPlans(accraUser);

      expect(
        plans.single.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(plans.single.lastChecklistResetKey, '2026-08-14');
    });

    test('keeps checked items before the reset boundary', () async {
      now = DateTime.utc(2026, 8, 14, 1);
      await _createPlan(clockedPlanService, accraUser);

      final plans = await clockedPlanService.listPlans(accraUser);

      expect(plans.single.items[1].isChecked, isTrue);
      expect(plans.single.lastChecklistResetKey, isNull);
    });

    test('resets at most once per workout day', () async {
      await _createPlan(clockedPlanService, accraUser);
      final resetPlan = (await clockedPlanService.listPlans(accraUser)).single;
      await clockedPlanService.updatePlan(
        user: accraUser,
        planId: resetPlan.id,
        title: 'Morning Workout Plan',
        items: const <PlanItem>[
          PlanItem(id: 'item-1', title: 'Water bottle'),
          PlanItem(id: 'item-2', title: 'Gym towel', isChecked: true),
        ],
        gymSession: 'morning',
        packingTime: '07:30',
        reminder: 'one_hour_before',
      );

      now = DateTime.utc(2026, 8, 14, 6);
      final plans = await clockedPlanService.listPlans(accraUser);

      expect(plans.single.items[1].isChecked, isTrue);
      expect(plans.single.lastChecklistResetKey, '2026-08-14');
    });

    test(
      'does not reset when the workout time has already passed today',
      () async {
        now = DateTime.utc(2026, 8, 14, 8, 30);
        await _createPlan(clockedPlanService, accraUser);

        final plans = await clockedPlanService.listPlans(accraUser);

        expect(plans.single.items[1].isChecked, isTrue);
        expect(plans.single.lastChecklistResetKey, isNull);
      },
    );

    test('applies midnight wrap when computing the reset boundary', () async {
      now = DateTime.utc(2026, 8, 14, 23);
      await clockedPlanService.createPlan(
        user: accraUser,
        title: 'Late Plan',
        items: const <PlanItem>[PlanItem(id: 'item-1', title: 'Shoes')],
        gymSession: 'morning',
        packingTime: '00:15',
        reminder: 'on_time',
      );

      final plans = await clockedPlanService.listPlans(accraUser);

      expect(plans.single.lastChecklistResetKey, '2026-08-15');
    });

    test('falls back to UTC for unknown timezones', () async {
      final unknownZoneUser = User(
        id: 'user-unknown-zone',
        username: 'unknown',
        email: 'unknown@example.com',
        passwordHash: 'hash',
        timezone: 'Not/AZone',
        createdAt: DateTime.utc(2026),
      );
      await _createPlan(clockedPlanService, unknownZoneUser);

      final plans = await clockedPlanService.listPlans(unknownZoneUser);

      expect(
        plans.single.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(plans.single.lastChecklistResetKey, '2026-08-14');
    });

    test(
      'clears the reset key when packing time changes but not on toggles',
      () async {
        await _createPlan(clockedPlanService, accraUser);
        final resetPlan = (await clockedPlanService.listPlans(
          accraUser,
        )).single;

        final toggledPlan = await clockedPlanService.updatePlan(
          user: accraUser,
          planId: resetPlan.id,
          title: 'Morning Workout Plan',
          items: const <PlanItem>[
            PlanItem(id: 'item-1', title: 'Water bottle'),
            PlanItem(id: 'item-2', title: 'Gym towel', isChecked: true),
          ],
          gymSession: 'morning',
          packingTime: '07:30',
          reminder: 'one_hour_before',
        );

        expect(toggledPlan.lastChecklistResetKey, '2026-08-14');

        final rescheduledPlan = await clockedPlanService.updatePlan(
          user: accraUser,
          planId: toggledPlan.id,
          title: 'Evening Workout Plan',
          items: const <PlanItem>[PlanItem(id: 'item-1', title: 'Shoes')],
          gymSession: 'evening',
          packingTime: '18:45',
          reminder: 'on_time',
        );

        expect(rescheduledPlan.lastChecklistResetKey, isNull);
      },
    );

    test('getPlan applies the daily reset', () async {
      final plan = await _createPlan(clockedPlanService, accraUser);

      final refreshedPlan = await clockedPlanService.getPlan(
        user: accraUser,
        planId: plan.id,
      );

      expect(
        refreshedPlan.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(refreshedPlan.lastChecklistResetKey, '2026-08-14');
    });
  });
}

Future<Plan> _createPlan(PlanService planService, User user) {
  return planService.createPlan(
    user: user,
    title: 'Morning Workout Plan',
    items: const <PlanItem>[
      PlanItem(id: 'item-1', title: 'Water bottle'),
      PlanItem(id: 'item-2', title: 'Gym towel', isChecked: true),
    ],
    gymSession: 'morning',
    packingTime: '07:30',
    reminder: 'one_hour_before',
  );
}
