import 'package:hoplixi/main_db/core/repositories/base/recovery_codes_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/recovery_codes_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class RecoveryCodesHistoryNormalizer implements VaultHistoryTypeNormalizer {
  RecoveryCodesHistoryNormalizer({
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodeValuesHistoryDao,
    required this.recoveryCodesRepository,
  });

  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;
  final RecoveryCodesRepository recoveryCodesRepository;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await recoveryCodesHistoryDao
        .getRecoveryCodesHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    final values = await recoveryCodeValuesHistoryDao
        .getRecoveryCodeValuesByHistoryId(historyId);

    return RecoveryCodesHistoryPayload(
      codesCount: item.codesCount,
      usedCount: item.usedCount,
      generatedAt: item.generatedAt,
      oneTime: item.oneTime,
      valuesCount: values.length,
      missingValuesCount: values.where((v) => v.code == null).length,
      usedValuesCount: values.where((v) => v.used).length,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await recoveryCodesRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.recoveryCodes;
    final codes = view.codes;

    return RecoveryCodesHistoryPayload(
      codesCount: codes.length,
      usedCount: codes.where((c) => c.used).length,
      generatedAt: item.generatedAt,
      oneTime: item.oneTime,
      valuesCount: codes.length,
      missingValuesCount: 0,
      usedValuesCount: codes.where((c) => c.used).length,
    );
  }
}
