import 'package:result_dart/result_dart.dart';

import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/vault_items/vault_items.dart';
import 'vault_snapshot_type_handler.dart';

class DocumentSnapshotHandler implements VaultSnapshotTypeHandler {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! DocumentViewDto) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Document snapshot',
          entity: 'document',
        ),
      );
    }

    // Base snapshot already written by VaultSnapshotWriter.
    // Document versions are managed by the document versioning subsystem.
    return const Success(unit);
  }
}
