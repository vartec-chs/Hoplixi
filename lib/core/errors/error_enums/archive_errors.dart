import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ArchiveErrorCode {
  archiveFailed('ARCHIVE_FAILED'),
  unarchiveFailed('UNARCHIVE_FAILED'),
  invalidPassword('ARCHIVE_INVALID_PASSWORD'),
  corrupted('ARCHIVE_CORRUPTED'),
  notFound('ARCHIVE_NOT_FOUND'),
  writeFailed('ARCHIVE_WRITE_FAILED'),
  unknown('ARCHIVE_UNKNOWN_ERROR');

  final String value;
  const ArchiveErrorCode(this.value);
}
