import 'package:hoplixi/vault_db/core/repositories/base/license_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/license_key_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class LicenseKeyHistoryNormalizer implements VaultHistoryTypeNormalizer {
  LicenseKeyHistoryNormalizer({
    required this.licenseKeyHistoryDao,
    required this.licenseKeyRepository,
  });

  final LicenseKeyHistoryDao licenseKeyHistoryDao;
  final LicenseKeyRepository licenseKeyRepository;

  @override
  VaultItemType get type => VaultItemType.licenseKey;

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await licenseKeyHistoryDao
            .getLicenseKeyHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          LicenseKeyHistoryPayload(
            productName: item.productName,
            vendor: item.vendor,
            licenseKey: item.licenseKey,
            licenseType: item.licenseType,
            licenseTypeOther: item.licenseTypeOther,
            accountEmail: item.accountEmail,
            accountUsername: item.accountUsername,
            purchaseEmail: item.purchaseEmail,
            orderNumber: item.orderNumber,
            purchaseDate: item.purchaseDate,
            purchasePrice: item.purchasePrice,
            currency: item.currency,
            validFrom: item.validFrom,
            validTo: item.validTo,
            renewalDate: item.renewalDate,
            seats: item.seats,
            activationLimit: item.activationLimit,
            activationsUsed: item.activationsUsed,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории лицензионного ключа',
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
        final viewOpt = (await licenseKeyRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.licenseKey;
          return Some(
            LicenseKeyHistoryPayload(
              productName: item.productName,
              vendor: item.vendor,
              licenseKey: item.licenseKey,
              licenseType: item.licenseType,
              licenseTypeOther: item.licenseTypeOther,
              accountEmail: item.accountEmail,
              accountUsername: item.accountUsername,
              purchaseEmail: item.purchaseEmail,
              orderNumber: item.orderNumber,
              purchaseDate: item.purchaseDate,
              purchasePrice: item.purchasePrice,
              currency: item.currency,
              validFrom: item.validFrom,
              validTo: item.validTo,
              renewalDate: item.renewalDate,
              seats: item.seats,
              activationLimit: item.activationLimit,
              activationsUsed: item.activationsUsed,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
