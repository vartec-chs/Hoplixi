import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
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
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! PasswordViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Password snapshot',
            entity: 'password',
          );
        }

        final pw = view.password;

        await passwordHistoryDao.insertPasswordHistory(
          PasswordHistoryCompanion.insert(
            historyId: historyId,
            login: Value(pw.login),
            email: Value(pw.email),
            password: Value(includeSecrets ? pw.password : null),
            url: Value(pw.url),
            expiresAt: Value(pw.expiresAt),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка пароля',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
