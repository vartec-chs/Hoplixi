import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class SshKeySnapshotHandler implements VaultSnapshotTypeHandler {
  SshKeySnapshotHandler({required this.sshKeyHistoryDao});

  final SshKeyHistoryDao sshKeyHistoryDao;

  @override
  VaultItemType get type => VaultItemType.sshKey;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! SshKeyViewDto) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for SshKey snapshot',
          entity: 'sshKey',
        ),
      );
    }

    final sk = view.sshKey;

    await sshKeyHistoryDao.insertSshKeyHistory(
      SshKeyHistoryCompanion.insert(
        historyId: historyId,
        publicKey: Value(sk.publicKey),
        privateKey: Value(includeSecrets ? sk.privateKey : null),
        keyType: Value(sk.keyType),
        keyTypeOther: Value(sk.keyTypeOther),
        keySize: Value(sk.keySize),
      ),
    );

    return const Success(unit);
  }
}
