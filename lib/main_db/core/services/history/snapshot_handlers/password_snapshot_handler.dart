import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class PasswordSnapshotHandler implements VaultSnapshotTypeHandler {
  PasswordSnapshotHandler({required this.passwordHistoryDao});

  final PasswordHistoryDao passwordHistoryDao;

  @override
  VaultItemType get type => VaultItemType.password;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! PasswordViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Password snapshot',
          entity: 'password',
        ),
      );
    }

    final password = view.password;

    await passwordHistoryDao.insertPasswordHistory(
      PasswordHistoryCompanion.insert(
        historyId: historyId,
        login: Value(password.login),
        email: Value(password.email),
        password: Value(includeSecrets ? password.password : null),
        url: Value(password.url),
        expiresAt: Value(password.expiresAt),
      ),
    );

    return const Success(unit);
  }
}
