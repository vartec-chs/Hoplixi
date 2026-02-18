import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей OTP.
@DataClassName('OtpHistoryData')
class OtpHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// ID связанного пароля (snapshot)
  TextColumn get passwordItemId => text().nullable()();

  /// Тип OTP (snapshot)
  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('totp'))();

  /// Издатель (snapshot)
  TextColumn get issuer => text().nullable()();

  /// Имя аккаунта (snapshot)
  TextColumn get accountName => text().nullable()();

  /// Секрет (snapshot)
  BlobColumn get secret => blob()();

  /// Кодировка секрета (snapshot)
  TextColumn get secretEncoding =>
      textEnum<SecretEncoding>().withDefault(const Constant('BASE32'))();

  /// Алгоритм (snapshot)
  TextColumn get algorithm =>
      textEnum<AlgorithmOtp>().withDefault(const Constant('SHA1'))();

  /// Количество цифр (snapshot)
  IntColumn get digits => integer().withDefault(const Constant(6))();

  /// Период (snapshot)
  IntColumn get period => integer().withDefault(const Constant(30))();

  /// Счётчик (snapshot)
  IntColumn get counter => integer().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'otp_history';
}
