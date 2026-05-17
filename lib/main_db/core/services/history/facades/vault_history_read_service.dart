import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../models/dto/dto.dart';
import '../../../models/mappers/history/vault_snapshot_history_mapper.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/filters/history/vault_snapshot_history_filter.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../readers/readers.dart';

class VaultHistoryReadService {
  VaultHistoryReadService({
    required this.snapshotFilterDao,
    required this.snapshotsHistoryDao,
    required this.readerRegistry,
    required this.genericReader,
  });

  final VaultSnapshotHistoryFilterDao snapshotFilterDao;
  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultHistoryCardReaderRegistry readerRegistry;
  final GenericHistoryCardReader genericReader;

  Future<DbResult<List<VaultHistoryCardDto>>> getFilteredCards(
    VaultSnapshotHistoryFilter filter,
  ) async {
    try {
      final snapshots = await snapshotFilterDao.getFiltered(filter);
      if (snapshots.isEmpty) return Success(const []);
      final cards = await _assembleCards(snapshots);
      return Success(cards);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }

  Future<DbResult<VaultHistoryCardDto>> getCardByHistoryId(
    String historyId,
  ) async {
    try {
      final snapshot = await snapshotsHistoryDao.getSnapshotById(historyId);
      if (snapshot == null) {
        return Failure(
          DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId),
        );
      }
      final cards = await _assembleCards([snapshot]);
      if (cards.isEmpty) {
        return Failure(
          DBCoreError.notFound(entity: 'HistorySnapshotData', id: historyId),
        );
      }
      return Success(cards.first);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
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
