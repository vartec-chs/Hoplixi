import 'package:hoplixi/main_db/core/repositories/base/license_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
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
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await licenseKeyHistoryDao.getLicenseKeyHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return LicenseKeyHistoryPayload(
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
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await licenseKeyRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.licenseKey;

    return LicenseKeyHistoryPayload(
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
    );
  }
}
