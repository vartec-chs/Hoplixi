import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/bank_card_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/certificate_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/contact_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/crypto_wallet_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/document_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/file_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/identity_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/license_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/loyalty_card_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/note_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/otp_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/password_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/recovery_codes_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/ssh_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/wifi_repository.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

class VaultTypedViewResolver {
  VaultTypedViewResolver({
    required this.apiKeyRepository,
    required this.passwordRepository,
    required this.bankCardRepository,
    required this.noteRepository,
    required this.otpRepository,
    required this.documentRepository,
    required this.fileRepository,
    required this.contactRepository,
    required this.sshKeyRepository,
    required this.certificateRepository,
    required this.cryptoWalletRepository,
    required this.wifiRepository,
    required this.identityRepository,
    required this.licenseKeyRepository,
    required this.recoveryCodesRepository,
    required this.loyaltyCardRepository,
  });

  final ApiKeyRepository apiKeyRepository;
  final PasswordRepository passwordRepository;
  final BankCardRepository bankCardRepository;
  final NoteRepository noteRepository;
  final OtpRepository otpRepository;
  final DocumentRepository documentRepository;
  final FileRepository fileRepository;
  final ContactRepository contactRepository;
  final SshKeyRepository sshKeyRepository;
  final CertificateRepository certificateRepository;
  final CryptoWalletRepository cryptoWalletRepository;
  final WifiRepository wifiRepository;
  final IdentityRepository identityRepository;
  final LicenseKeyRepository licenseKeyRepository;
  final RecoveryCodesRepository recoveryCodesRepository;
  final LoyaltyCardRepository loyaltyCardRepository;

  Future<Object?> getView({
    required String itemId,
    required VaultItemType type,
  }) async {
    return switch (type) {
      VaultItemType.apiKey => apiKeyRepository.getViewById(itemId),
      VaultItemType.password => passwordRepository.getViewById(itemId),
      VaultItemType.bankCard => bankCardRepository.getViewById(itemId),
      VaultItemType.note => noteRepository.getViewById(itemId),
      VaultItemType.otp => otpRepository.getViewById(itemId),
      VaultItemType.document => documentRepository.getViewById(itemId),
      VaultItemType.file => fileRepository.getViewById(itemId),
      VaultItemType.contact => contactRepository.getViewById(itemId),
      VaultItemType.sshKey => sshKeyRepository.getViewById(itemId),
      VaultItemType.certificate => certificateRepository.getViewById(itemId),
      VaultItemType.cryptoWallet => cryptoWalletRepository.getViewById(itemId),
      VaultItemType.wifi => wifiRepository.getViewById(itemId),
      VaultItemType.identity => identityRepository.getViewById(itemId),
      VaultItemType.licenseKey => licenseKeyRepository.getViewById(itemId),
      VaultItemType.recoveryCodes => recoveryCodesRepository.getViewById(
        itemId,
      ),
      VaultItemType.loyaltyCard => loyaltyCardRepository.getViewById(itemId),
    };
  }
}
