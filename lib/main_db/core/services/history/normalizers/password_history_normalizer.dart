import 'package:hoplixi/main_db/core/repositories/base/password_repository.dart';

import '../../../daos/daos.dart';
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
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await passwordHistoryDao.getPasswordHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return PasswordHistoryPayload(
      login: item.login,
      email: item.email,
      password: item.password,
      url: item.url,
      expiresAt: item.expiresAt,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await passwordRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.password;

    return PasswordHistoryPayload(
      login: item.login,
      email: item.email,
      password: item.password,
      url: item.url,
      expiresAt: item.expiresAt,
    );
  }
}
