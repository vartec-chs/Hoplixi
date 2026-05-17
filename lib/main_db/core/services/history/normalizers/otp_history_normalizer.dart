import 'package:hoplixi/main_db/core/repositories/base/otp_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/otp_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class OtpHistoryNormalizer implements VaultHistoryTypeNormalizer {
  OtpHistoryNormalizer({
    required this.otpHistoryDao,
    required this.otpRepository,
  });

  final OtpHistoryDao otpHistoryDao;
  final OtpRepository otpRepository;

  @override
  VaultItemType get type => VaultItemType.otp;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await otpHistoryDao.getOtpHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return OtpHistoryPayload(
      otpType: item.type,
      issuer: item.issuer,
      accountName: item.accountName,
      secret: item.secret,
      algorithm: item.algorithm,
      digits: item.digits,
      period: item.period,
      counter: item.counter,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await otpRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.otp;

    return OtpHistoryPayload(
      otpType: item.type,
      issuer: item.issuer,
      accountName: item.accountName,
      secret: item.secret,
      algorithm: item.algorithm,
      digits: item.digits,
      period: item.period,
      counter: item.counter,
    );
  }
}
