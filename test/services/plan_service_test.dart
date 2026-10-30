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

  test('deleting a missing plan is safe to retry', () async {
    await planService.deletePlan(user: user, planId: 'missing-plan');
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

    test('clears yesterday checks at midnight', () async {
      await _createPlan(clockedPlanService, accraUser);
      now = DateTime.utc(2026, 8, 15);

      final plans = await clockedPlanService.listPlans(accraUser);

      expect(
        plans.single.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(plans.single.lastChecklistResetKey, '2026-08-15');
    });

    test('keeps checks made today regardless of packing time', () async {
      now = DateTime.utc(2026, 8, 14, 1);
      await _createPlan(clockedPlanService, accraUser);

      final plans = await clockedPlanService.listPlans(accraUser);

      expect(plans.single.items[1].isChecked, isTrue);
      expect(plans.single.lastChecklistResetKey, '2026-08-14');
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
      'catches up after missed days even after packing time',
      () async {
        now = DateTime.utc(2026, 8, 14, 8, 30);
        await _createPlan(clockedPlanService, accraUser);
        now = DateTime.utc(2026, 8, 18, 8, 30);

        final plans = await clockedPlanService.listPlans(accraUser);

        expect(plans.single.items[1].isChecked, isFalse);
        expect(plans.single.lastChecklistResetKey, '2026-08-18');
      },
    );

    test('late packing time does not advance the completion day', () async {
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

      expect(plans.single.lastChecklistResetKey, '2026-08-14');
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
      now = DateTime.utc(2026, 8, 15);

      final plans = await clockedPlanService.listPlans(unknownZoneUser);

      expect(
        plans.single.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(plans.single.lastChecklistResetKey, '2026-08-15');
    });

    test(
      'packing time changes and toggles retain the calendar day',
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

        expect(rescheduledPlan.lastChecklistResetKey, '2026-08-14');
      },
    );

    test('getPlan applies the daily reset', () async {
      final plan = await _createPlan(clockedPlanService, accraUser);
      now = DateTime.utc(2026, 8, 15);

      final refreshedPlan = await clockedPlanService.getPlan(
        user: accraUser,
        planId: plan.id,
      );

      expect(
        refreshedPlan.items.every((item) => !item.isChecked),
        isTrue,
      );
      expect(refreshedPlan.lastChecklistResetKey, '2026-08-15');
      expect(refreshedPlan.revision, plan.revision);
    });

    test('a delayed old-day edit preserves current-day completion', () async {
      final plan = await _createPlan(clockedPlanService, accraUser);
      now = DateTime.utc(2026, 8, 15, 12);
      final updated = await clockedPlanService.updatePlan(
        user: accraUser,
        planId: plan.id,
        title: plan.title,
        items: plan.items,
        gymSession: plan.gymSession,
        packingTime: plan.packingTime,
        reminder: plan.reminder,
        completionDate: '2026-08-14',
        expectedRevision: plan.revision,
      );
      expect(updated.items.every((item) => !item.isChecked), isTrue);
      expect(updated.lastChecklistResetKey, '2026-08-15');
      expect(updated.revision, 1);
      final checkedToday = await clockedPlanService.updatePlan(
        user: accraUser,
        planId: plan.id,
        title: plan.title,
        items: const [PlanItem(id: 'item-2', title: 'Towel', isChecked: true)],
        gymSession: plan.gymSession,
        packingTime: plan.packingTime,
        reminder: plan.reminder,
        completionDate: '2026-08-15',
        expectedRevision: 1,
      );
      final delayed = await clockedPlanService.updatePlan(
        user: accraUser,
        planId: plan.id,
        title: 'Renamed offline',
        items: const [PlanItem(id: 'item-2', title: 'Renamed towel')],
        gymSession: plan.gymSession,
        packingTime: plan.packingTime,
        reminder: plan.reminder,
        completionDate: '2026-08-14',
        expectedRevision: checkedToday.revision,
      );
      expect(delayed.items.single.isChecked, isTrue);
    });

    test('stale revision cannot overwrite another device', () async {
      final plan = await _createPlan(clockedPlanService, accraUser);
      Future<Plan> update() => clockedPlanService.updatePlan(
        user: accraUser,
        planId: plan.id,
        title: plan.title,
        items: [],
        gymSession: plan.gymSession,
        packingTime: plan.packingTime,
        reminder: plan.reminder,
        completionDate: '2026-08-14',
        expectedRevision: plan.revision,
      );
      expect((await update()).items, isEmpty);
      await expectLater(
        update(),
        throwsA(
          isA<PlanServiceException>().having(
            (e) => e.code,
            'code',
            PlanErrorCode.conflict,
          ),
        ),
      );
    });

    test('uses the account timezone rather than the server timezone', () async {
      final newYork = user.copyWith(timezone: 'America/New_York');
      now = DateTime.utc(2026, 3, 8, 4, 59);
      final plan = await _createPlan(clockedPlanService, newYork);
      expect(plan.lastChecklistResetKey, '2026-03-07');
      now = DateTime.utc(2026, 3, 8, 5);
      expect(
        (await clockedPlanService.getPlan(
          user: newYork,
          planId: plan.id,
        )).items.every((i) => !i.isChecked),
        isTrue,
      );
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
