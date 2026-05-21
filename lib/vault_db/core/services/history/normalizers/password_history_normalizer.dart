import 'package:hoplixi/vault_db/core/repositories/base/password_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/password_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class PasswordHistoryNormalizer implements VaultHistoryTypeNormalizer {
  PasswordHistoryNormalizer({
    required this.passwordHistoryDao,
    required this.passwordRepository,
  });

  final PasswordHistoryDao passwordHistoryDao;
  final PasswordRepository passwordRepository;

  @override
  VaultItemType get type => VaultItemType.password;

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await passwordHistoryDao.getPasswordHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          PasswordHistoryPayload(
            login: item.login,
            email: item.email,
            password: item.password,
            url: item.url,
            expiresAt: item.expiresAt,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории пароля',
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
        final viewOpt = (await passwordRepository.getViewById(itemId))
            .getOrThrow();
        return viewOpt.fold(
          (view) {
            final item = view.password;
            return Some(
              PasswordHistoryPayload(
                login: item.login,
                email: item.email,
                password: item.password,
                url: item.url,
                expiresAt: item.expiresAt,
              ),
            );
          },
          () => const None(),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния пароля',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
