import 'package:result_dart/result_dart.dart';

import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import 'vault_snapshot_type_handler.dart';

class DocumentSnapshotHandler implements VaultSnapshotTypeHandler {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! DocumentViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Document snapshot',
            entity: 'document',
          );
        }

        // Base snapshot already written by VaultSnapshotWriter.
        // Document versions are managed by the document versioning subsystem.
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка документа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
