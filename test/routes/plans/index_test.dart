import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:fit_prep_backend/controllers/plan_controller.dart';
import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/models/user.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:fit_prep_backend/services/plan_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/plans/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  final user = User(
    id: 'user-1',
    username: 'caleb',
    email: 'caleb@example.com',
    passwordHash: 'hash',
    timezone: 'Africa/Accra',
    createdAt: DateTime(2026),
  );
  const items = <PlanItem>[
    PlanItem(id: 'item-1', title: 'Water bottle'),
    PlanItem(id: 'item-2', title: 'Gym towel'),
  ];

  late PlanService planService;
  late _MockRequestContext context;

  setUp(() {
    planService = PlanService(planRepository: InMemoryPlanRepository());
    context = _MockRequestContext();
    when(() => context.read<PlanController>()).thenReturn(
      const PlanController(),
    );
    when(() => context.read<PlanService>()).thenReturn(planService);
    when(() => context.read<User>()).thenReturn(user);
  });

  test('POST /plans creates a full plan', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/plans'),
        headers: {'content-type': ContentType.json.value},
        body: jsonEncode({
          'title': 'Morning Workout Plan',
          'items': [
            {'id': 'item-1', 'title': 'Water bottle', 'is_checked': false},
            {'id': 'item-2', 'title': 'Gym towel', 'is_checked': true},
          ],
          'gym_session': 'morning',
          'packing_time': '07:30',
          'reminder': 'one_hour_before',
        }),
      ),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    final plan = body['plan'] as Map<String, dynamic>;
    final planItems = plan['items'] as List<dynamic>;

    expect(response.statusCode, HttpStatus.created);
    expect(plan['title'], 'Morning Workout Plan');
    expect(plan['user_id'], user.id);
    expect(planItems, hasLength(2));
    expect(plan['gym_session'], 'morning');
    expect(plan['packing_time'], '07:30');
    expect(plan['reminder_time'], '06:30');
    expect(plan['reminder'], 'one_hour_before');
  });

  test('GET /plans lists full plans', () async {
    await planService.createPlan(
      user: user,
      title: 'Morning Workout Plan',
      items: items,
      gymSession: 'morning',
      packingTime: '07:30',
      reminder: 'one_hour_before',
    );
    when(() => context.request).thenReturn(
      Request.get(Uri.parse('http://localhost/plans')),
    );

    final response = await route.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    final plans = body['plans'] as List<dynamic>;
    final plan = plans.first as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok);
    expect(plans, hasLength(1));
    expect(plan['items'], hasLength(2));
    expect(plan['gym_session'], 'morning');
  });
}
