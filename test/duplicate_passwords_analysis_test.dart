import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/duplicate_passwords/screen/duplicate_passwords_screen.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

void main() {
  late MainStore store;

  setUp(() {
    store = MainStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  Future<String> createPassword(
    String name,
    String password, {
    bool archived = false,
    bool deleted = false,
  }) async {
    final id = await store.passwordDao.createPassword(
      CreatePasswordDto(name: name, password: password, login: '$name-login'),
    );

    if (archived) {
      await store.vaultItemDao.toggleArchive(id, true);
    }
    if (deleted) {
      await store.vaultItemDao.softDelete(id);
    }

    return id;
  }

  test('returns active passwords grouped by duplicate value only', () async {
    final firstId = await createPassword('first', 'same-password');
    final secondId = await createPassword('second', 'same-password');
    await createPassword('third', 'unique-password');

    final groups = await store.passwordFilterDao.getDuplicatePasswordGroups();

    expect(groups, hasLength(1));
    expect(groups.single.count, 2);
    expect(
      groups.single.items.map((item) => item.id),
      containsAll([firstId, secondId]),
    );
  });

  test('ignores archived and deleted passwords', () async {
    final activeId = await createPassword('active', 'same-password');
    final archivedId = await createPassword(
      'archived',
      'same-password',
      archived: true,
    );
    final deletedId = await createPassword(
      'deleted',
      'same-password',
      deleted: true,
    );

    final groups = await store.passwordFilterDao.getDuplicatePasswordGroups();

    expect(groups, isEmpty);

    await createPassword('active-duplicate', 'same-password');
    final updatedGroups = await store.passwordFilterDao
        .getDuplicatePasswordGroups();

    expect(updatedGroups, hasLength(1));
    final ids = updatedGroups.single.items.map((item) => item.id);
    expect(ids, contains(activeId));
    expect(ids, isNot(contains(archivedId)));
    expect(ids, isNot(contains(deletedId)));
  });

  testWidgets('renders duplicate groups after first frame analysis', (
    tester,
  ) async {
    await createPassword('first', 'same-password');
    await createPassword('second', 'same-password');

    await tester.pumpWidget(_buildDuplicatePasswordsTestApp(store));

    expect(find.text('Группа 1'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Группа 1'), findsOneWidget);
    expect(find.text('2 записи используют одинаковый пароль'), findsOneWidget);
  });

  testWidgets('opens password edit route on card tap', (tester) async {
    final passwordId = await createPassword('first', 'same-password');
    await createPassword('second', 'same-password');

    await tester.pumpWidget(_buildDuplicatePasswordsTestApp(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();

    expect(find.text('edit:$passwordId'), findsOneWidget);
  });
}

Widget _buildDuplicatePasswordsTestApp(MainStore store) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DuplicatePasswordsScreen(),
      ),
      GoRoute(
        path: '/dashboard/passwords/edit/:id',
        builder: (context, state) => Text('edit:${state.pathParameters['id']}'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      passwordFilterDaoProvider.overrideWith((ref) async {
        return store.passwordFilterDao;
      }),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}
