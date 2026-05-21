import 'package:hoplixi/vault_db/core/repositories/base/ssh_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await sshKeyHistoryDao.getSshKeyHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          SshKeyHistoryPayload(
            publicKey: item.publicKey,
            privateKey: item.privateKey,
            keyType: item.keyType,
            keyTypeOther: item.keyTypeOther,
            keySize: item.keySize,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории SSH ключа',
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
        final viewOpt = (await sshKeyRepository.getViewById(itemId)).getOrThrow();
        return viewOpt.fold(
          (view) {
            final item = view.sshKey;
            return Some(
              SshKeyHistoryPayload(
                publicKey: item.publicKey,
                privateKey: item.privateKey,
                keyType: item.keyType,
                keyTypeOther: item.keyTypeOther,
                keySize: item.keySize,
              ),
            );
          },
          () => const None(),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния SSH ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
