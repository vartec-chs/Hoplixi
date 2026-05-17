import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/note_history_payload.dart';
import 'vault_history_restore_handler.dart';

class NoteHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  NoteHistoryRestoreHandler({required this.noteItemsDao});

  final NoteItemsDao noteItemsDao;

  @override
  VaultItemType get type => VaultItemType.note;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! NoteHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Note restore',
          entity: 'note',
        ),
      );
    }

    await noteItemsDao.upsertNoteItem(
      NoteItemsCompanion(
        itemId: Value(base.itemId),
        deltaJson: Value(payload.deltaJson ?? ''),
        content: Value(payload.content ?? ''),
      ),
    );

    return const Success(unit);
  }
}
