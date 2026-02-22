import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/forms/api_key_form/screens/api_key_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/bank_card_form/screens/bank_card_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/certificate_form/screens/certificate_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/contact_form/screens/contact_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/crypto_wallet_form/screens/crypto_wallet_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/document_form/screens/document_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/file_form/screens/file_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/identity_form/screens/identity_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/license_key_form/screens/license_key_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/screens/note_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/screens/otp_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/password_form/screens/password_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/recovery_codes_form/screens/recovery_codes_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/ssh_key_form/screens/ssh_key_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/wifi_form/screens/wifi_form_screen.dart';

/// Виджет-обертка для создания/редактирования сущностей
/// Возвращает соответствующий экран формы в зависимости от типа сущности
class EntityAddEdit extends StatelessWidget {
  const EntityAddEdit({
    super.key,
    required this.entity,
    required this.isEdit,
    this.id,
  });

  /// Тип сущности
  final EntityType entity;

  /// Режим редактирования (true) или создания (false)
  final bool isEdit;

  /// ID сущности для редактирования (null для режима создания)
  final String? id;

  @override
  Widget build(BuildContext context) {
    switch (entity) {
      case EntityType.password:
        return PasswordFormScreen(passwordId: id);
      case EntityType.note:
        return NoteFormScreen(noteId: id);
      case EntityType.bankCard:
        return BankCardFormScreen(bankCardId: id);
      case EntityType.file:
        return FileFormScreen(fileId: id);
      case EntityType.otp:
        return OtpFormScreen(otpId: id);
      case EntityType.document:
        return DocumentFormScreen(documentId: id);
      case EntityType.apiKey:
        return ApiKeyFormScreen(apiKeyId: id);
      case EntityType.contact:
        return ContactFormScreen(contactId: id);
      case EntityType.sshKey:
        return SshKeyFormScreen(sshKeyId: id);
      case EntityType.certificate:
        return CertificateFormScreen(certificateId: id);
      case EntityType.cryptoWallet:
        return CryptoWalletFormScreen(cryptoWalletId: id);
      case EntityType.wifi:
        return WifiFormScreen(wifiId: id);
      case EntityType.identity:
        return IdentityFormScreen(identityId: id);
      case EntityType.licenseKey:
        return LicenseKeyFormScreen(licenseKeyId: id);
      case EntityType.recoveryCodes:
        return RecoveryCodesFormScreen(recoveryCodesId: id);
    }
  }
}
