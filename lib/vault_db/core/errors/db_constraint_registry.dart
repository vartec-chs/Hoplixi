import 'db_constraint_descriptor.dart';
import 'registries/api_key_registry.dart';
import 'registries/bank_card_registry.dart';
import 'registries/certificate_registry.dart';
import 'registries/contact_registry.dart';
import 'registries/crypto_wallet_registry.dart';
import 'registries/document_registry.dart';
import 'registries/file_registry.dart';
import 'registries/identity_registry.dart';
import 'registries/license_key_registry.dart';
import 'registries/loyalty_card_registry.dart';
import 'registries/note_registry.dart';
import 'registries/otp_registry.dart';
import 'registries/password_registry.dart';
import 'registries/recovery_codes_registry.dart';
import 'registries/ssh_key_registry.dart';
import 'registries/system_registry.dart';
import 'registries/vault_item_registry.dart';

final Map<String, DbConstraintDescriptor> dbConstraintRegistry = {
  ...apiKeyRegistry,
  ...bankCardRegistry,
  ...certificateRegistry,
  ...contactRegistry,
  ...cryptoWalletRegistry,
  ...documentRegistry,
  ...fileRegistry,
  ...identityRegistry,
  ...licenseKeyRegistry,
  ...loyaltyCardRegistry,
  ...noteRegistry,
  ...otpRegistry,
  ...passwordRegistry,
  ...recoveryCodesRegistry,
  ...sshKeyRegistry,
  ...systemRegistry,
  ...vaultItemRegistry,
};
