import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:riverpod/riverpod.dart';

import '../dao/index.dart';
import 'main_store_provider.dart';

typedef _DaoFactory<TDao> = TDao Function(MainStore store);

Future<TDao> _ensureDao<TDao>(Ref ref, _DaoFactory<TDao> factory) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }
  return factory(store);
}

final passwordDaoProvider = FutureProvider<PasswordDao>(
  (ref) => _ensureDao(ref, (store) => PasswordDao(store)),
);

final apiKeyDaoProvider = FutureProvider<ApiKeyDao>(
  (ref) => _ensureDao(ref, (store) => ApiKeyDao(store)),
);

final contactDaoProvider = FutureProvider<ContactDao>(
  (ref) => _ensureDao(ref, (store) => ContactDao(store)),
);

final sshKeyDaoProvider = FutureProvider<SshKeyDao>(
  (ref) => _ensureDao(ref, (store) => SshKeyDao(store)),
);

final certificateDaoProvider = FutureProvider<CertificateDao>(
  (ref) => _ensureDao(ref, (store) => CertificateDao(store)),
);

final cryptoWalletDaoProvider = FutureProvider<CryptoWalletDao>(
  (ref) => _ensureDao(ref, (store) => CryptoWalletDao(store)),
);

final wifiDaoProvider = FutureProvider<WifiDao>(
  (ref) => _ensureDao(ref, (store) => WifiDao(store)),
);

final identityDaoProvider = FutureProvider<IdentityDao>(
  (ref) => _ensureDao(ref, (store) => IdentityDao(store)),
);

final licenseKeyDaoProvider = FutureProvider<LicenseKeyDao>(
  (ref) => _ensureDao(ref, (store) => LicenseKeyDao(store)),
);

final recoveryCodesDaoProvider = FutureProvider<RecoveryCodesDao>(
  (ref) => _ensureDao(ref, (store) => RecoveryCodesDao(store)),
);

final passwordHistoryDaoProvider = FutureProvider<PasswordHistoryDao>(
  (ref) => _ensureDao(ref, (store) => PasswordHistoryDao(store)),
);

final apiKeyHistoryDaoProvider = FutureProvider<ApiKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => ApiKeyHistoryDao(store)),
);

final sshKeyHistoryDaoProvider = FutureProvider<SshKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => SshKeyHistoryDao(store)),
);

final certificateHistoryDaoProvider = FutureProvider<CertificateHistoryDao>(
  (ref) => _ensureDao(ref, (store) => CertificateHistoryDao(store)),
);

final cryptoWalletHistoryDaoProvider = FutureProvider<CryptoWalletHistoryDao>(
  (ref) => _ensureDao(ref, (store) => CryptoWalletHistoryDao(store)),
);

final wifiHistoryDaoProvider = FutureProvider<WifiHistoryDao>(
  (ref) => _ensureDao(ref, (store) => WifiHistoryDao(store)),
);

final identityHistoryDaoProvider = FutureProvider<IdentityHistoryDao>(
  (ref) => _ensureDao(ref, (store) => IdentityHistoryDao(store)),
);

final licenseKeyHistoryDaoProvider = FutureProvider<LicenseKeyHistoryDao>(
  (ref) => _ensureDao(ref, (store) => LicenseKeyHistoryDao(store)),
);

final recoveryCodesHistoryDaoProvider = FutureProvider<RecoveryCodesHistoryDao>(
  (ref) => _ensureDao(ref, (store) => RecoveryCodesHistoryDao(store)),
);

final otpDaoProvider = FutureProvider<OtpDao>(
  (ref) => _ensureDao(ref, (store) => OtpDao(store)),
);

final otpHistoryDaoProvider = FutureProvider<OtpHistoryDao>(
  (ref) => _ensureDao(ref, (store) => OtpHistoryDao(store)),
);

final noteDaoProvider = FutureProvider<NoteDao>(
  (ref) => _ensureDao(ref, (store) => NoteDao(store)),
);

final noteHistoryDaoProvider = FutureProvider<NoteHistoryDao>(
  (ref) => _ensureDao(ref, (store) => NoteHistoryDao(store)),
);

final bankCardDaoProvider = FutureProvider<BankCardDao>(
  (ref) => _ensureDao(ref, (store) => BankCardDao(store)),
);

final bankCardHistoryDaoProvider = FutureProvider<BankCardHistoryDao>(
  (ref) => _ensureDao(ref, (store) => BankCardHistoryDao(store)),
);

final fileDaoProvider = FutureProvider<FileDao>(
  (ref) => _ensureDao(ref, (store) => FileDao(store)),
);

final fileHistoryDaoProvider = FutureProvider<FileHistoryDao>(
  (ref) => _ensureDao(ref, (store) => FileHistoryDao(store)),
);

final documentHistoryDaoProvider = FutureProvider<DocumentHistoryDao>(
  (ref) => _ensureDao(ref, (store) => DocumentHistoryDao(store)),
);

final contactHistoryDaoProvider = FutureProvider<ContactHistoryDao>(
  (ref) => _ensureDao(ref, (store) => ContactHistoryDao(store)),
);

final categoryDaoProvider = FutureProvider<CategoryDao>(
  (ref) => _ensureDao(ref, (store) => CategoryDao(store)),
);

final iconDaoProvider = FutureProvider<IconDao>(
  (ref) => _ensureDao(ref, (store) => IconDao(store)),
);

final tagDaoProvider = FutureProvider<TagDao>(
  (ref) => _ensureDao(ref, (store) => TagDao(store)),
);

final passwordFilterDaoProvider = FutureProvider<PasswordFilterDao>(
  (ref) => _ensureDao(ref, (store) => PasswordFilterDao(store)),
);

final apiKeyFilterDaoProvider = FutureProvider<ApiKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => ApiKeyFilterDao(store)),
);

final contactFilterDaoProvider = FutureProvider<ContactFilterDao>(
  (ref) => _ensureDao(ref, (store) => ContactFilterDao(store)),
);

final sshKeyFilterDaoProvider = FutureProvider<SshKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => SshKeyFilterDao(store)),
);

final certificateFilterDaoProvider = FutureProvider<CertificateFilterDao>(
  (ref) => _ensureDao(ref, (store) => CertificateFilterDao(store)),
);

final cryptoWalletFilterDaoProvider = FutureProvider<CryptoWalletFilterDao>(
  (ref) => _ensureDao(ref, (store) => CryptoWalletFilterDao(store)),
);

final wifiFilterDaoProvider = FutureProvider<WifiFilterDao>(
  (ref) => _ensureDao(ref, (store) => WifiFilterDao(store)),
);

final identityFilterDaoProvider = FutureProvider<IdentityFilterDao>(
  (ref) => _ensureDao(ref, (store) => IdentityFilterDao(store)),
);

final licenseKeyFilterDaoProvider = FutureProvider<LicenseKeyFilterDao>(
  (ref) => _ensureDao(ref, (store) => LicenseKeyFilterDao(store)),
);

final recoveryCodesFilterDaoProvider = FutureProvider<RecoveryCodesFilterDao>(
  (ref) => _ensureDao(ref, (store) => RecoveryCodesFilterDao(store)),
);

final otpFilterDaoProvider = FutureProvider<OtpFilterDao>(
  (ref) => _ensureDao(ref, (store) => OtpFilterDao(store)),
);

final noteFilterDaoProvider = FutureProvider<NoteFilterDao>(
  (ref) => _ensureDao(ref, (store) => NoteFilterDao(store)),
);

final bankCardFilterDaoProvider = FutureProvider<BankCardFilterDao>(
  (ref) => _ensureDao(ref, (store) => BankCardFilterDao(store)),
);

final fileFilterDaoProvider = FutureProvider<FileFilterDao>(
  (ref) => _ensureDao(ref, (store) => FileFilterDao(store)),
);

final noteLinkDaoProvider = FutureProvider<NoteLinkDao>(
  (ref) => _ensureDao(ref, (store) => NoteLinkDao(store)),
);

final storeMetaDaoProvider = FutureProvider<StoreMetaDao>(
  (ref) => _ensureDao(ref, (store) => StoreMetaDao(store)),
);

final documentDaoProvider = FutureProvider<DocumentDao>(
  (ref) => _ensureDao(ref, (store) => DocumentDao(store)),
);

final documentFilterDaoProvider = FutureProvider<DocumentFilterDao>(
  (ref) => _ensureDao(ref, (store) => DocumentFilterDao(store)),
);

final vaultItemDaoProvider = FutureProvider<VaultItemDao>(
  (ref) => _ensureDao(ref, (store) => VaultItemDao(store)),
);

final storeSettingsDaoProvider = FutureProvider<StoreSettingsDao>(
  (ref) => _ensureDao(ref, (store) => StoreSettingsDao(store)),
);
