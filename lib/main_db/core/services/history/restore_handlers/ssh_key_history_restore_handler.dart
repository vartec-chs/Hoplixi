import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/ssh_key_history_payload.dart';
import 'vault_history_restore_handler.dart';

class SshKeyHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  SshKeyHistoryRestoreHandler({
    required this.sshKeyItemsDao,
  });

  final SshKeyItemsDao sshKeyItemsDao;

  @override
  VaultItemType get type => VaultItemType.sshKey;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! SshKeyHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for SshKey restore',
          entity: 'sshKey',
        ),
      );
    }

    if (payload.privateKey == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message: 'Нельзя восстановить запись: в снимке отсутствует обязательное поле "privateKey"',
          entity: 'sshKey',
        ),
      );
    }

    await sshKeyItemsDao.upsertSshKeyItem(
      SshKeyItemsCompanion(
        itemId: Value(base.itemId),
        publicKey: Value(payload.publicKey),
        privateKey: Value(payload.privateKey!),
        keyType: Value(payload.keyType),
        keyTypeOther: Value(payload.keyTypeOther),
        keySize: Value(payload.keySize),
      ),
    );

    return const Success(unit);
  }
}
