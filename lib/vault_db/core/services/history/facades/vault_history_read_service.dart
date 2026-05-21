import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../models/filters/history/vault_snapshot_history_filter.dart';
import '../../../models/mappers/history/vault_snapshot_history_mapper.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../readers/readers.dart';

class VaultHistoryReadService {
  VaultHistoryReadService({
    required this.db,
    required this.readerRegistry,
    required this.genericReader,
  }) : snapshotFilterDao = db.vaultSnapshotHistoryFilterDao,
       snapshotsHistoryDao = db.vaultSnapshotsHistoryDao;

  final VaultDB db;
  final VaultSnapshotHistoryFilterDao snapshotFilterDao;
  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultHistoryCardReaderRegistry readerRegistry;
  final GenericHistoryCardReader genericReader;

  AsyncDbResult<List<VaultHistoryCardDto>> getFilteredCards(
    VaultSnapshotHistoryFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () async {
        final snapshots = await snapshotFilterDao.getFiltered(filter);
        if (snapshots.isEmpty) return const [];
        return await _assembleCards(snapshots);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных карточек истории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<VaultHistoryCardDto>> getCardByHistoryId(
    String historyId,
  ) {
    return ResultUtils.tryCatchAsync(
      () async {
        final snapshot = await snapshotsHistoryDao.getSnapshotById(historyId);
        if (snapshot == null) return const None();

        final cards = await _assembleCards([snapshot]);
        if (cards.isEmpty) {
          throw DBCoreError.notFound(
            entity: 'HistorySnapshotData',
            id: historyId,
            message: 'Failed to assemble card data for snapshot: $historyId',
          );
        }
        return Some(cards.first);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки истории по ID',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  Future<List<VaultHistoryCardDto>> _assembleCards(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    if (snapshots.isEmpty) return const [];

    final Map<VaultItemType, List<VaultSnapshotHistoryData>> grouped = {};
    for (final s in snapshots) {
      grouped.putIfAbsent(s.type, () => []).add(s);
    }

    final Map<String, VaultHistoryCardDto> cardsByHistoryId = {};

    for (final entry in grouped.entries) {
      final reader = readerRegistry.getReader(entry.key);

      final cards = reader == null
          ? await genericReader.getCardsBySnapshots(entry.value)
          : await reader.getCardsBySnapshots(entry.value);

      cardsByHistoryId.addAll(cards);
    }

    return [
      for (final snapshot in snapshots)
        cardsByHistoryId[snapshot.id] ??
            GenericHistoryCardDto(snapshot: snapshot.toVaultSnapshotCardDto()),
    ];
  }
}
