import 'package:hoplixi/vault_db/core/repositories/base/note_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await noteHistoryDao.getNoteHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          NoteHistoryPayload(deltaJson: item.deltaJson, content: item.content),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final viewOpt = (await noteRepository.getViewById(itemId)).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.note;
          return Some(
            NoteHistoryPayload(
              deltaJson: item.deltaJson,
              content: item.content,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния заметки',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
