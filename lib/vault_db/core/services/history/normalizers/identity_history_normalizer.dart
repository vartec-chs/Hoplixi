import 'package:hoplixi/vault_db/core/repositories/base/identity_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/identity_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class IdentityHistoryNormalizer implements VaultHistoryTypeNormalizer {
  IdentityHistoryNormalizer({
    required this.identityHistoryDao,
    required this.identityRepository,
  });

  final IdentityHistoryDao identityHistoryDao;
  final IdentityRepository identityRepository;

  @override
  VaultItemType get type => VaultItemType.identity;

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await identityHistoryDao.getIdentityHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          IdentityHistoryPayload(
            firstName: item.firstName,
            middleName: item.middleName,
            lastName: item.lastName,
            displayName: item.displayName,
            username: item.username,
            email: item.email,
            phone: item.phone,
            address: item.address,
            birthday: item.birthday,
            company: item.company,
            jobTitle: item.jobTitle,
            website: item.website,
            taxId: item.taxId,
            nationalId: item.nationalId,
            passportNumber: item.passportNumber,
            driverLicenseNumber: item.driverLicenseNumber,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории идентификатора',
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
        final viewOpt = (await identityRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.identity;
          return Some(
            IdentityHistoryPayload(
              firstName: item.firstName,
              middleName: item.middleName,
              lastName: item.lastName,
              displayName: item.displayName,
              username: item.username,
              email: item.email,
              phone: item.phone,
              address: item.address,
              birthday: item.birthday,
              company: item.company,
              jobTitle: item.jobTitle,
              website: item.website,
              taxId: item.taxId,
              nationalId: item.nationalId,
              passportNumber: item.passportNumber,
              driverLicenseNumber: item.driverLicenseNumber,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
