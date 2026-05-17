import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class NoteSnapshotHandler implements VaultSnapshotTypeHandler {
  NoteSnapshotHandler({required this.noteHistoryDao});

  final NoteHistoryDao noteHistoryDao;

  @override
  VaultItemType get type => VaultItemType.note;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! NoteViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Note snapshot',
          entity: 'note',
        ),
      );
    }

    final note = view.note;

    await noteHistoryDao.insertNoteHistory(
      NoteHistoryCompanion.insert(
        historyId: historyId,
        deltaJson: Value(includeSecrets ? note.deltaJson : null),
        content: Value(includeSecrets ? note.content : null),
      ),
    );

    return const Success(unit);
  }
}
