import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/bank_card_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/certificate_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/contact_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/crypto_wallet_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/document_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/file_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/identity_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/license_key_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/loyalty_card_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/note_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/otp_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/password_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/recovery_codes_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/ssh_key_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/category_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/tag_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/base/wifi_repository.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import 'main_store_manager_provider.dart';

final apiKeyRepositoryProvider = FutureProvider<ApiKeyRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return ApiKeyRepository(store);
});

final bankCardRepositoryProvider = FutureProvider<BankCardRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return BankCardRepository(store);
});

final certificateRepositoryProvider = FutureProvider<CertificateRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return CertificateRepository(store);
});

final contactRepositoryProvider = FutureProvider<ContactRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return ContactRepository(store);
});

final cryptoWalletRepositoryProvider = FutureProvider<CryptoWalletRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return CryptoWalletRepository(store);
});

final documentRepositoryProvider = FutureProvider<DocumentRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return DocumentRepository(store);
});

final fileRepositoryProvider = FutureProvider<FileRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return FileRepository(store);
});

final identityRepositoryProvider = FutureProvider<IdentityRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return IdentityRepository(store);
});

final licenseKeyRepositoryProvider = FutureProvider<LicenseKeyRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return LicenseKeyRepository(store);
});

final loyaltyCardRepositoryProvider = FutureProvider<LoyaltyCardRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return LoyaltyCardRepository(store);
});

final noteRepositoryProvider = FutureProvider<NoteRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return NoteRepository(store);
});

final otpRepositoryProvider = FutureProvider<OtpRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return OtpRepository(store);
});

final passwordRepositoryProvider = FutureProvider<PasswordRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return PasswordRepository(store);
});

final recoveryCodesRepositoryProvider = FutureProvider<RecoveryCodesRepository>(
  (ref) async {
    final store = await ref.watch(vaultDBProvider.future);
    return RecoveryCodesRepository(store);
  },
);

final sshKeyRepositoryProvider = FutureProvider<SshKeyRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return SshKeyRepository(store);
});

final wifiRepositoryProvider = FutureProvider<WifiRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return WifiRepository(store);
});

final categoryRepositoryProvider = FutureProvider<CategoryRepository>((
  ref,
) async {
  final store = await ref.watch(vaultDBProvider.future);
  return CategoryRepository(store);
});

final tagRepositoryProvider = FutureProvider<TagRepository>((ref) async {
  final store = await ref.watch(vaultDBProvider.future);
  return TagRepository(store);
});
