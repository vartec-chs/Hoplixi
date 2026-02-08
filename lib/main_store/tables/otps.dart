import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';
import 'notes.dart';
import 'passwords.dart';

@DataClassName('OtpsData')
class Otps extends Table {
  // Primary key
  TextColumn get id => text().clientDefault(() => const Uuid().v4())(); // UUID v4

  // Foreign keys
  TextColumn get passwordId => text().nullable().references(
    Passwords,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to passwords (optional)
  // Relations and metadata
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  // OTP authentication fields
  TextColumn get type => textEnum<OtpType>().withDefault(
    const Constant('totp'),
  )(); // Type: TOTP or HOTP

  TextColumn get issuer =>
      text().nullable()(); // Service name (e.g., "Google", "GitHub")
  TextColumn get accountName =>
      text().nullable()(); // Account identifier (e.g., email, username)

  BlobColumn get secret => blob()();
  TextColumn get secretEncoding => textEnum<SecretEncoding>().withDefault(
    const Constant('BASE32'),
  )(); // Encoding of the secret (BASE32, HEX, BINARY)

  TextColumn get noteId => text().nullable().references(
    Notes,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to notes

  // OTP configuration
  TextColumn get algorithm => textEnum<AlgorithmOtp>().withDefault(
    const Constant('SHA1'),
  )(); // HMAC algorithm (SHA1, SHA256, SHA512)
  IntColumn get digits => integer().withDefault(
    const Constant(6),
  )(); // Number of digits in OTP code (usually 6 or 8)
  IntColumn get period => integer().withDefault(
    const Constant(30),
  )(); // Time period in seconds for TOTP (usually 30)
  IntColumn get counter =>
      integer().nullable()(); // Counter for HOTP (only used when type = HOTP)

  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  //is archived
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  RealColumn get recentScore => real().nullable()(); // EWMA for sorting
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // For filters and UX

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'otps';

  @override
  List<String> get customConstraints => [
    // Constraint: counter is required for HOTP, but should be null for TOTP
    'CHECK ((type = \'hotp\' AND counter IS NOT NULL) OR (type = \'totp\' AND counter IS NULL))',
  ];
}
