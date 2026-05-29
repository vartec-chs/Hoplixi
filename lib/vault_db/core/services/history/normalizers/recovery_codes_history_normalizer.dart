import 'package:hoplixi/vault_db/core/repositories/base/recovery_codes_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/recovery_codes_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class RecoveryCodesHistoryNormalizer implements VaultHistoryTypeNormalizer {
  RecoveryCodesHistoryNormalizer({
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodesRepository,
  });

  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodesRepository recoveryCodesRepository;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await recoveryCodesHistoryDao
            .getRecoveryCodesHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          RecoveryCodesHistoryPayload(
            generatedAt: item.generatedAt,
            oneTime: item.oneTime,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final viewOpt = (await recoveryCodesRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.recoveryCodes;

          return Some(
            RecoveryCodesHistoryPayload(
              generatedAt: item.generatedAt,
              oneTime: item.oneTime,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
