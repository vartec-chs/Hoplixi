import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class SshKeySnapshotHandler implements VaultSnapshotTypeHandler {
  SshKeySnapshotHandler({required this.sshKeyHistoryDao});

  final SshKeyHistoryDao sshKeyHistoryDao;

  @override
  VaultItemType get type => VaultItemType.sshKey;

  @override
  AsyncDBResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return tryCatchAsync(
      () async {
        if (view is! SshKeyViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for SshKey snapshot',
            entity: 'sshKey',
          );
        }

        final sshKey = view.sshKey;

        await sshKeyHistoryDao.insertSshKeyHistory(
          SshKeyHistoryCompanion.insert(
            historyId: historyId,
            publicKey: Value(sshKey.publicKey),
            privateKey: Value(includeSecrets ? sshKey.privateKey : null),
            keyType: Value(sshKey.keyType),
            keyTypeOther: Value(sshKey.keyTypeOther),
            keySize: Value(sshKey.keySize),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка SSH ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
