import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

import 'vault_items.dart';

/// Type-specific таблица для OTP-кодов.
///
/// Содержит ТОЛЬКО поля, специфичные для OTP.
/// Общие поля (name, categoryId, isFavorite и т.д.)
/// хранятся в vault_items.
@DataClassName('OtpItemsData')
class OtpItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  @ReferenceName('otpItem')
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Связь с паролем (опционально)
  @ReferenceName('linkedPasswordItem')
  TextColumn get passwordItemId => text().nullable().references(
    VaultItems,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Тип OTP: TOTP или HOTP
  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('totp'))();

  /// Издатель (например, "Google", "GitHub")
  TextColumn get issuer => text().nullable()();

  /// Имя аккаунта (e.g., email, username)
  TextColumn get accountName => text().nullable()();

  /// Секретный ключ (encrypted blob)
  BlobColumn get secret => blob()();

  /// Кодировка секрета (BASE32, HEX, BINARY)
  TextColumn get secretEncoding =>
      textEnum<SecretEncoding>().withDefault(const Constant('BASE32'))();

  /// Алгоритм HMAC (SHA1, SHA256, SHA512)
  TextColumn get algorithm =>
      textEnum<AlgorithmOtp>().withDefault(const Constant('SHA1'))();

  /// Количество цифр в OTP (обычно 6 или 8)
  IntColumn get digits => integer().withDefault(const Constant(6))();

  /// Период обновления в секундах для TOTP
  IntColumn get period => integer().withDefault(const Constant(30))();

  /// Счётчик для HOTP (null для TOTP)
  IntColumn get counter => integer().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'otp_items';

  @override
  List<String> get customConstraints => [
    "CHECK ((type = 'hotp' AND counter IS NOT NULL) "
        "OR (type = 'totp' AND counter IS NULL))",
  ];
}
