import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/mappers/history/vault_snapshot_history_mapper.dart';

import '../../../daos/daos.dart';
import '../../../models/dto_history/cards/cards_exports.dart';
import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_type_reader.dart';

class CertificateHistoryCardReader implements VaultHistoryTypeReader {
  CertificateHistoryCardReader({required this.certificateHistoryDao});

  final CertificateHistoryDao certificateHistoryDao;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    if (snapshots.isEmpty) return const {};

    final historyIds = snapshots.map((e) => e.id).toList();

    final dataByHistoryId = await certificateHistoryDao
        .getCertificateHistoryCardDataByHistoryIds(historyIds);

    final result = <String, VaultHistoryCardDto>{};

    for (final snapshot in snapshots) {
      final data = dataByHistoryId[snapshot.id];

      final snapshotDto = snapshot.toVaultSnapshotCardDto();

      result[snapshot.id] = data == null
          ? GenericHistoryCardDto(snapshot: snapshotDto)
          : CertificateHistoryCardDto(snapshot: snapshotDto, certificate: data);
    }

    return result;
  }
}
