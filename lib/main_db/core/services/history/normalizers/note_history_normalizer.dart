import 'package:hoplixi/main_db/core/repositories/base/note_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/note_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class NoteHistoryNormalizer implements VaultHistoryTypeNormalizer {
  NoteHistoryNormalizer({
    required this.noteHistoryDao,
    required this.noteRepository,
  });

  final NoteHistoryDao noteHistoryDao;
  final NoteRepository noteRepository;

  @override
  VaultItemType get type => VaultItemType.note;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await noteHistoryDao.getNoteHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return NoteHistoryPayload(
      deltaJson: item.deltaJson,
      content: item.content,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await noteRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.note;

    return NoteHistoryPayload(
      deltaJson: item.deltaJson,
      content: item.content,
    );
  }
}
