import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum MainDatabaseErrorCode {
  invalidPassword('DB_INVALID_PASSWORD'),
  notInitialized('DB_NOT_INITIALIZED'),
  alreadyInitialized('DB_ALREADY_INITIALIZED'),
  alreadyOpen('DB_STORE_ALREADY_OPEN'),
  connectionFailed('DB_CONNECTION_FAILED'),
  queryFailed('DB_QUERY_FAILED'),
  recordNotFound('DB_RECORD_NOT_FOUND'),
  migrationFailed('DB_MIGRATION_FAILED'),
  storeMigrationRequired('DB_STORE_MIGRATION_REQUIRED'),
  storeVersionTooNew('DB_STORE_VERSION_TOO_NEW'),
  corrupted('DB_CORRUPTED'),
  encryptionFailed('DB_ENCRYPTION_FAILED'),
  decryptionFailed('DB_DECRYPTION_FAILED'),
  transactionFailed('DB_TRANSACTION_FAILED'),
  validationError('DB_VALIDATION_ERROR'),
  deleteFailed('DB_DELETE_FAILED'),
  updateFailed('DB_UPDATE_FAILED'),
  unknown('DB_UNKNOWN_ERROR');

  final String value;
  const MainDatabaseErrorCode(this.value);
}
