import 'dart:io';

import 'package:fit_prep_backend/database/app_database.dart';
import 'package:fit_prep_backend/models/plan.dart';
import 'package:fit_prep_backend/repositories/plan_repository.dart';
import 'package:fit_prep_backend/repositories/postgres_plan_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final url = Platform.environment['PLAN_TEST_DATABASE_URL'];
  test(
    'Postgres revisions are atomic and stale writes preserve items',
    () async {
      final database = AppDatabase.fromUrl(url!);
      final userId = 'plan-sync-test-${DateTime.now().microsecondsSinceEpoch}';
      final repository = PostgresPlanRepository(database: database);
      try {
        await database.ensureMigrated();
        // The additive migration must also work against an existing schema.
        final second = AppDatabase.fromUrl(url);
        try {
          await second.ensureMigrated();
        } finally {
          await second.close();
        }
        await database.execute(
          Sql.named('''
INSERT INTO users (id, username, email, password_hash)
VALUES (@id, @id, @id, 'test-only')
'''),
          parameters: {'id': userId},
        );
        final plan = await repository.create(
          Plan(
            id: '$userId-plan',
            userId: userId,
            title: 'Original',
            items: const [PlanItem(id: 'water', title: 'Water')],
            gymSession: 'morning',
            packingTime: '07:30',
            reminder: 'on_time',
            createdAt: DateTime.utc(2026, 10, 27),
            lastChecklistResetKey: '2026-10-27',
          ),
        );
        Future<bool> update(String title) async {
          try {
            await repository.update(
              plan.copyWith(
                title: title,
                items: const [
                  PlanItem(id: 'water', title: 'Water', isChecked: true),
                ],
              ),
              expectedRevision: 0,
            );
            return true;
          } on PlanConflictException {
            return false;
          }
        }

        final outcomes = await Future.wait([
          update('Device A'),
          update('Device B'),
        ]);
        expect(outcomes.where((success) => success), hasLength(1));
        final saved = (await repository.findByIdForUser(
          id: plan.id,
          userId: userId,
        ))!;
        expect(saved.revision, 1);
        expect(saved.items.single.isChecked, isTrue);
        await expectLater(
          repository.update(plan, expectedRevision: 0),
          throwsA(isA<PlanConflictException>()),
        );
        final unchanged = (await repository.findByIdForUser(
          id: plan.id,
          userId: userId,
        ))!;
        expect(unchanged.title, saved.title);
        expect(unchanged.items.single.isChecked, isTrue);
        final empty = await repository.update(
          saved.copyWith(items: []),
          expectedRevision: 1,
        );
        expect(empty.revision, 2);
        expect(
          (await repository.findByIdForUser(
            id: plan.id,
            userId: userId,
          ))!.items,
          isEmpty,
        );
      } finally {
        await database.execute(
          Sql.named('DELETE FROM users WHERE id = @id'),
          parameters: {'id': userId},
        );
        await database.close();
      }
    },
    skip: url == null
        ? 'Set PLAN_TEST_DATABASE_URL to a disposable PostgreSQL database.'
        : false,
  );
}
