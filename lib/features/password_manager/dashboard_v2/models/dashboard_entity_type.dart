import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum DashboardEntityType {
  password('passwords', 'Пароли', LucideIcons.lock),
  note('notes', 'Заметки', LucideIcons.stickyNote),
  bankCard('bank_cards', 'Банковские карты', LucideIcons.creditCard),
  file('files', 'Файлы', LucideIcons.file),
  otp('otps', 'OTP/2FA', LucideIcons.shieldCheck),
  document('documents', 'Документы', LucideIcons.fileText),
  contact('contacts', 'Контакты', LucideIcons.idCard),
  apiKey('api_keys', 'API-ключи', LucideIcons.key),
  sshKey('ssh_keys', 'SSH-ключи', LucideIcons.keyRound),
  certificate('certificates', 'Сертификаты', LucideIcons.shieldCheck),
  cryptoWallet('crypto_wallets', 'Криптокошельки', LucideIcons.wallet),
  wifi('wifi', 'Wi-Fi', LucideIcons.wifi),
  identity('identities', 'Идентификация', LucideIcons.idCard),
  licenseKey('license_keys', 'Лицензии', LucideIcons.key),
  recoveryCodes('recovery_codes', 'Коды восстановления', LucideIcons.key),
  loyaltyCard('loyalty_cards', 'Карты лояльности', LucideIcons.creditCard);

  const DashboardEntityType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static DashboardEntityType? fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}
