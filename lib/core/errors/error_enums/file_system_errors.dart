import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum FileSystemErrorCode {
  notFound('FS_NOT_FOUND'),
  permissionDenied('FS_PERMISSION_DENIED'),
  readFailed('FS_READ_FAILED'),
  writeFailed('FS_WRITE_FAILED'),
  deleteFailed('FS_DELETE_FAILED'),
  createFailed('FS_CREATE_FAILED'),
  invalidPath('FS_INVALID_PATH'),
  alreadyExists('FS_ALREADY_EXISTS'),
  insufficientSpace('FS_NO_SPACE'),
  unknown('FS_UNKNOWN_ERROR');

  final String value;
  const FileSystemErrorCode(this.value);
}