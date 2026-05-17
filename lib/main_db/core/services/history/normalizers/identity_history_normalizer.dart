import 'package:hoplixi/main_db/core/repositories/base/identity_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
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
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await identityHistoryDao.getIdentityHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return IdentityHistoryPayload(
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
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await identityRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.identity;

    return IdentityHistoryPayload(
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
    );
  }
}
