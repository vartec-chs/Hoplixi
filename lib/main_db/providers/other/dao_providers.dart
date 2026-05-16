import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

import '../../core/old/daos/daos.dart';
import '../main_store_manager_provider.dart';

typedef _DaoFactory<TDao> = TDao Function(MainStore store);

Future<TDao> _ensureDao<TDao>(Ref ref, _DaoFactory<TDao> factory) async {
  await ref.watch(mainStoreManagerStateProvider.future);
  final store = ref.read(mainStoreManagerStateProvider.notifier).currentStore;
  if (store == null) {
    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: 'Хранилище не открыто',
      timestamp: DateTime.now(),
    );
  }
  return factory(store);
}

final passwordDaoProvider = FutureProvider<PasswordDao>(
  (ref) => _ensureDao(ref, (store) => store.passwordDao),
);

final apiKeyDaoProvider = FutureProvider<ApiKeyDao>(
  (ref) => _ensureDao(ref, (store) => store.apiKeyDao),
);

final contactDaoProvider = FutureProvider<ContactDao>(
  (ref) => _ensureDao(ref, (store) => store.contactDao),
);

final sshKeyDaoProvider = FutureProvider<SshKeyDao>(
  (ref) => _ensureDao(ref, (store) => store.sshKeyDao),
);

final certificateDaoProvider = FutureProvider<CertificateDao>(
  (ref) => _ensureDao(ref, (store) => store.certificateDao),
);

final cryptoWalletDaoProvider = FutureProvider<CryptoWalletDao>(
  (ref) => _ensureDao(ref, (store) => store.cryptoWalletDao),
);

final wifiDaoProvider = FutureProvider<WifiDao>(
  (ref) => _ensureDao(ref, (store) => store.wifiDao),
);

final identityDaoProvider = FutureProvider<IdentityDao>(
  (ref) => _ensureDao(ref, (store) => store.identityDao),
);

final licenseKeyDaoProvider = FutureProvider<LicenseKeyDao>(
  (ref) => _ensureDao(ref, (store) => store.licenseKeyDao),
);

final recoveryCodesDaoProvider = FutureProvider<RecoveryCodesDao>(
  (ref) => _ensureDao(ref, (store) => store.recoveryCodesDao),
);

final passwordHistoryDaoProvider = FutureProvider<PasswordHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.passwordHistoryDao),
);

final apiKeyHistoryDaoProvider = FutureProvider<ApiKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.apiKeyHistoryDao),
);

final sshKeyHistoryDaoProvider = FutureProvider<SshKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.sshKeyHistoryDao),
);

final certificateHistoryDaoProvider = FutureProvider<CertificateHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.certificateHistoryDao),
);

final cryptoWalletHistoryDaoProvider = FutureProvider<CryptoWalletHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.cryptoWalletHistoryDao),
);

final wifiHistoryDaoProvider = FutureProvider<WifiHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.wifiHistoryDao),
);

final identityHistoryDaoProvider = FutureProvider<IdentityHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.identityHistoryDao),
);

final licenseKeyHistoryDaoProvider = FutureProvider<LicenseKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.licenseKeyHistoryDao),
);

final recoveryCodesHistoryDaoProvider = FutureProvider<RecoveryCodesHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.recoveryCodesHistoryDao),
);

final otpDaoProvider = FutureProvider<OtpDao>(
  (ref) => _ensureDao(ref, (store) => store.otpDao),
);

final otpHistoryDaoProvider = FutureProvider<OtpHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.otpHistoryDao),
);

final noteDaoProvider = FutureProvider<NoteDao>(
  (ref) => _ensureDao(ref, (store) => store.noteDao),
);

final noteHistoryDaoProvider = FutureProvider<NoteHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.noteHistoryDao),
);

final bankCardDaoProvider = FutureProvider<BankCardDao>(
  (ref) => _ensureDao(ref, (store) => store.bankCardDao),
);

final bankCardHistoryDaoProvider = FutureProvider<BankCardHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.bankCardHistoryDao),
);

final fileDaoProvider = FutureProvider<FileDao>(
  (ref) => _ensureDao(ref, (store) => store.fileDao),
);

final fileHistoryDaoProvider = FutureProvider<FileHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.fileHistoryDao),
);

final documentHistoryDaoProvider = FutureProvider<DocumentHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.documentHistoryDao),
);

final contactHistoryDaoProvider = FutureProvider<ContactHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.contactHistoryDao),
);

final categoryDaoProvider = FutureProvider<CategoryDao>(
  (ref) => _ensureDao(ref, (store) => store.categoryDao),
);

final iconDaoProvider = FutureProvider<IconDao>(
  (ref) => _ensureDao(ref, (store) => store.iconDao),
);

final tagDaoProvider = FutureProvider<TagDao>(
  (ref) => _ensureDao(ref, (store) => store.tagDao),
);

final passwordFilterDaoProvider = FutureProvider<PasswordFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.passwordFilterDao),
);

final apiKeyFilterDaoProvider = FutureProvider<ApiKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.apiKeyFilterDao),
);

final contactFilterDaoProvider = FutureProvider<ContactFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.contactFilterDao),
);

final sshKeyFilterDaoProvider = FutureProvider<SshKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.sshKeyFilterDao),
);

final certificateFilterDaoProvider = FutureProvider<CertificateFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.certificateFilterDao),
);

final cryptoWalletFilterDaoProvider = FutureProvider<CryptoWalletFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.cryptoWalletFilterDao),
);

final wifiFilterDaoProvider = FutureProvider<WifiFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.wifiFilterDao),
);

final identityFilterDaoProvider = FutureProvider<IdentityFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.identityFilterDao),
);

final licenseKeyFilterDaoProvider = FutureProvider<LicenseKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.licenseKeyFilterDao),
);

final recoveryCodesFilterDaoProvider = FutureProvider<RecoveryCodesFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.recoveryCodesFilterDao),
);

final otpFilterDaoProvider = FutureProvider<OtpFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.otpFilterDao),
);

final noteFilterDaoProvider = FutureProvider<NoteFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.noteFilterDao),
);

final bankCardFilterDaoProvider = FutureProvider<BankCardFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.bankCardFilterDao),
);

final fileFilterDaoProvider = FutureProvider<FileFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.fileFilterDao),
);

final vaultEventHistoryFilterDaoProvider =
    FutureProvider<VaultEventHistoryFilterDao>(
      (ref) => _ensureDao(ref, (store) => store.vaultEventHistoryFilterDao),
    );

final vaultSnapshotHistoryFilterDaoProvider =
    FutureProvider<VaultSnapshotHistoryFilterDao>(
      (ref) => _ensureDao(ref, (store) => store.vaultSnapshotHistoryFilterDao),
    );

final noteLinkDaoProvider = FutureProvider<NoteLinkDao>(
  (ref) => _ensureDao(ref, (store) => store.noteLinkDao),
);

final storeMetaDaoProvider = FutureProvider<StoreMetaDao>(
  (ref) => _ensureDao(ref, (store) => store.storeMetaDao),
);

final documentDaoProvider = FutureProvider<DocumentDao>(
  (ref) => _ensureDao(ref, (store) => store.documentDao),
);

final documentFilterDaoProvider = FutureProvider<DocumentFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.documentFilterDao),
);

final customFieldDaoProvider = FutureProvider<CustomFieldDao>(
  (ref) => _ensureDao(ref, (store) => store.customFieldDao),
);

final customFieldHistoryDaoProvider = FutureProvider<CustomFieldHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.customFieldHistoryDao),
);

final vaultItemDaoProvider = FutureProvider<VaultItemDao>(
  (ref) => _ensureDao(ref, (store) => store.vaultItemDao),
);

final storeSettingsDaoProvider = FutureProvider<StoreSettingsDao>(
  (ref) => _ensureDao(ref, (store) => store.storeSettingsDao),
);

final loyaltyCardDaoProvider = FutureProvider<LoyaltyCardDao>(
  (ref) => _ensureDao(ref, (store) => store.loyaltyCardDao),
);

final loyaltyCardHistoryDaoProvider = FutureProvider<LoyaltyCardHistoryDao>(
  (ref) => _ensureDao(ref, (store) => store.loyaltyCardHistoryDao),
);

final loyaltyCardFilterDaoProvider = FutureProvider<LoyaltyCardFilterDao>(
  (ref) => _ensureDao(ref, (store) => store.loyaltyCardFilterDao),
);
