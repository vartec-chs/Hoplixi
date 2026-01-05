import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('OtpsHistoryData')
class OtpsHistory extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get originalOtpId => text()(); // ID of original OTP
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'

  // OTP data snapshot
  TextColumn get type => textEnum<OtpType>().withDefault(
    const Constant('totp'),
  )(); // Type: TOTP or HOTP
  TextColumn get issuer => text().nullable()(); // Service name
  TextColumn get accountName => text().nullable()(); // Account identifier
  BlobColumn get secret => blob()();
  TextColumn get secretEncoding => textEnum<SecretEncoding>().withDefault(
    const Constant('BASE32'),
  )(); // Encoding of the secret
  TextColumn get notes => text().nullable()();

  // OTP configuration snapshot
  TextColumn get algorithm => textEnum<AlgorithmOtp>().withDefault(
    const Constant('SHA1'),
  )(); // HMAC algorithm
  IntColumn get digits =>
      integer().withDefault(const Constant(6))(); // Number of digits
  IntColumn get period =>
      integer().withDefault(const Constant(30))(); // Time period in seconds
  IntColumn get counter => integer().nullable()(); // Counter for HOTP

  // Relations
  TextColumn get passwordId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action

  // State flags snapshot
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  RealColumn get recentScore => real().nullable()(); // EWMA snapshot
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Last used snapshot

  // Timestamps
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get originalLastUsedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'otps_history';
}
