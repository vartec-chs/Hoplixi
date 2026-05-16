import '../../daos/daos.dart';
import '../../models/dto_history/cards/cards_exports.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../models/mappers/history/vault_snapshot_history_mapper.dart';
import 'vault_history_restore_policy_service.dart';

class NormalizedHistorySnapshot {
  const NormalizedHistorySnapshot({
    required this.snapshot,
    required this.fields,
    required this.sensitiveKeys,
    required this.customFields,
    required this.restoreWarnings,
  });

  final VaultSnapshotCardDto snapshot;
  final Map<String, Object?> fields;
  final Set<String> sensitiveKeys;
  final List<dynamic> customFields; // TODO: DTO for custom fields
  final List<String> restoreWarnings;
}

class VaultHistoryNormalizedLoader {
  VaultHistoryNormalizedLoader({
    required this.snapshotsHistoryDao,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.restorePolicyService,
    // Add other DAOs as needed
  });

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final VaultHistoryRestorePolicyService restorePolicyService;

  Future<NormalizedHistorySnapshot?> loadHistorySnapshot(String historyId) async {
    final snapshotData = await snapshotsHistoryDao.getSnapshotById(historyId);
    if (snapshotData == null) return null;

    final snapshotDto = snapshotData.toVaultSnapshotCardDto();
    final fields = <String, Object?>{};
    final sensitiveKeys = <String>{};

    // Common fields from snapshot
    fields['name'] = snapshotDto.name;
    fields['description'] = snapshotDto.description;

    switch (snapshotDto.type) {
      case VaultItemType.apiKey:
        final data = await apiKeyHistoryDao.getApiKeyHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['service'] = item.service;
          fields['key'] = item.key;
          fields['tokenType'] = item.tokenType?.name;
          fields['environment'] = item.environment?.name;
          fields['expiresAt'] = item.expiresAt;
          fields['revokedAt'] = item.revokedAt;
          fields['owner'] = item.owner;
          fields['baseUrl'] = item.baseUrl;
          
          sensitiveKeys.add('key');
        }
        break;
      case VaultItemType.password:
        final data = await passwordHistoryDao.getPasswordHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['login'] = item.login;
          fields['email'] = item.email;
          fields['password'] = item.password;
          fields['url'] = item.url;
          fields['expiresAt'] = item.expiresAt;

          sensitiveKeys.add('password');
        }
        break;
      // Stage 1: Others generic or partial
      default:
        break;
    }

    final normalized = NormalizedHistorySnapshot(
      snapshot: snapshotDto,
      fields: fields,
      sensitiveKeys: sensitiveKeys,
      customFields: const [], // TODO: load custom fields history
      restoreWarnings: [],
    );

    return NormalizedHistorySnapshot(
      snapshot: snapshotDto,
      fields: fields,
      sensitiveKeys: sensitiveKeys,
      customFields: const [],
      restoreWarnings: restorePolicyService.restoreWarnings(normalized),
    );
  }

  Future<NormalizedHistorySnapshot?> loadCurrentSnapshot({
    required String itemId,
    required VaultItemType type,
  }) async {
    // TODO: Implement loading current live state and normalizing it
    return null;
  }
}
