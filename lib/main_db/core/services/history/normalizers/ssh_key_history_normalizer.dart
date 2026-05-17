import 'package:hoplixi/main_db/core/repositories/base/ssh_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/ssh_key_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class SshKeyHistoryNormalizer implements VaultHistoryTypeNormalizer {
  SshKeyHistoryNormalizer({
    required this.sshKeyHistoryDao,
    required this.sshKeyRepository,
  });

  final SshKeyHistoryDao sshKeyHistoryDao;
  final SshKeyRepository sshKeyRepository;

  @override
  VaultItemType get type => VaultItemType.sshKey;

  @override
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await sshKeyHistoryDao.getSshKeyHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return SshKeyHistoryPayload(
      publicKey: item.publicKey,
      privateKey: item.privateKey,
      keyType: item.keyType,
      keyTypeOther: item.keyTypeOther,
      keySize: item.keySize,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await sshKeyRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.sshKey;

    return SshKeyHistoryPayload(
      publicKey: item.publicKey,
      privateKey: item.privateKey,
      keyType: item.keyType,
      keyTypeOther: item.keyTypeOther,
      keySize: item.keySize,
    );
  }
}
