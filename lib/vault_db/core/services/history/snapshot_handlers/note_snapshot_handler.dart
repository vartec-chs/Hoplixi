import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class NoteSnapshotHandler implements VaultSnapshotTypeHandler {
  NoteSnapshotHandler({required this.noteHistoryDao});

  final NoteHistoryDao noteHistoryDao;

  @override
  VaultItemType get type => VaultItemType.note;

  @override
  AsyncDBResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return tryCatchAsync(
      () async {
        if (view is! NoteViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Note snapshot',
            entity: 'note',
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

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
