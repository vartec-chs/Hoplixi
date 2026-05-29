import 'package:hoplixi/vault_db/core/repositories/base/otp_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDBResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await otpHistoryDao.getOtpHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          OtpHistoryPayload(
            otpType: item.type,
            issuer: item.issuer,
            accountName: item.accountName,
            secret: item.secret,
            algorithm: item.algorithm,
            digits: item.digits,
            period: item.period,
            counter: item.counter,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории OTP',
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
        final viewOpt = (await otpRepository.getViewById(itemId)).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.otp;
          return Some(
            OtpHistoryPayload(
              otpType: item.type,
              issuer: item.issuer,
              accountName: item.accountName,
              secret: item.secret,
              algorithm: item.algorithm,
              digits: item.digits,
              period: item.period,
              counter: item.counter,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния OTP',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
