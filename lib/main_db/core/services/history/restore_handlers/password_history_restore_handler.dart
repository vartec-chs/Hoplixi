import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/password_history_payload.dart';
import 'vault_history_restore_handler.dart';

class PasswordHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  PasswordHistoryRestoreHandler({required this.passwordItemsDao});

  final PasswordItemsDao passwordItemsDao;

  @override
  VaultItemType get type => VaultItemType.password;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! PasswordHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Password restore',
          entity: 'password',
        ),
      );
    }

    if (payload.password == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message:
              'Нельзя восстановить пароль: в снимке отсутствует обязательное поле "password"',
          entity: 'password',
        ),
      );
    }

    await passwordItemsDao.upsertPasswordItem(
      PasswordItemsCompanion(
        itemId: Value(base.itemId),
        login: Value(payload.login),
        email: Value(payload.email),
        password: Value(payload.password!),
        url: Value(payload.url),
        expiresAt: Value(payload.expiresAt),
      ),
    );

    return const Success(unit);
  }
}
