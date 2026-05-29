import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/entities/api_key_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/bank_card_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/base_vault_entity_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/certificate_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/contact_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/crypto_wallet_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/document_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/file_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/identity_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/license_key_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/loyalty_card_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/note_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/otp_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/password_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/recovery_codes_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/ssh_key_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/wifi_service.dart';
import 'package:hoplixi/vault_db/core/services/history/facades/vault_history_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

/// Container for all vault entity services.
class VaultEntityServices {
  VaultEntityServices({
    required VaultDB db,
    required VaultRepositories repositories,
    required VaultHistoryService historyService,
    required VaultItemsStateService vaultItemsStateService,
  }) : _deps = VaultEntityServiceDeps(
         db: db,
         repositories: repositories,
         historyService: historyService,
         vaultItemsStateService: vaultItemsStateService,
       );

  final VaultEntityServiceDeps _deps;

  late final apiKey = ApiKeyService(
    deps: _deps,
    repository: _deps.repositories.apiKey,
  );

  late final bankCard = BankCardService(
    deps: _deps,
    repository: _deps.repositories.bankCard,
  );

  late final certificate = CertificateService(
    deps: _deps,
    repository: _deps.repositories.certificate,
  );

  late final contact = ContactService(
    deps: _deps,
    repository: _deps.repositories.contact,
  );

  late final cryptoWallet = CryptoWalletService(
    deps: _deps,
    repository: _deps.repositories.cryptoWallet,
  );

  late final document = DocumentService(
    deps: _deps,
    repository: _deps.repositories.document,
  );

  late final file = FileService(
    deps: _deps,
    repository: _deps.repositories.file,
  );

  late final identity = IdentityService(
    deps: _deps,
    repository: _deps.repositories.identity,
  );

  late final licenseKey = LicenseKeyService(
    deps: _deps,
    repository: _deps.repositories.licenseKey,
  );

  late final loyaltyCard = LoyaltyCardService(
    deps: _deps,
    repository: _deps.repositories.loyaltyCard,
  );

  late final note = NoteService(
    deps: _deps,
    repository: _deps.repositories.note,
  );

  late final otp = OtpService(deps: _deps, repository: _deps.repositories.otp);

  late final password = PasswordService(
    deps: _deps,
    repository: _deps.repositories.password,
  );

  late final recoveryCodes = RecoveryCodesService(
    deps: _deps,
    repository: _deps.repositories.recoveryCodes,
  );

  late final sshKey = SshKeyService(
    deps: _deps,
    repository: _deps.repositories.sshKey,
  );

  late final wifi = WifiService(
    deps: _deps,
    repository: _deps.repositories.wifi,
  );
}
