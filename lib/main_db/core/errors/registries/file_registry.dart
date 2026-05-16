import '../db_constraint_descriptor.dart';
import '../../tables/file/file_items.dart';
import '../../tables/file/file_metadata.dart';

final Map<String, DbConstraintDescriptor> fileRegistry = {
  // --- File Items ---
  FileItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_items_item_id_not_blank',
    entity: 'file',
    table: 'file_items',
    field: 'itemId',
    code: 'file.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  FileItemConstraint.metadataIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_items_metadata_id_not_blank',
    entity: 'file',
    table: 'file_items',
    field: 'metadataId',
    code: 'file.metadata_id.not_blank',
    message: 'ID метаданных не может быть пустым',
  ),

  // --- File Metadata ---
  FileMetadataConstraint.idNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_metadata_id_not_blank',
    entity: 'fileMetadata',
    table: 'file_metadata',
    field: 'id',
    code: 'file_metadata.id.not_blank',
    message: 'ID метаданных не может быть пустым',
  ),
  FileMetadataConstraint.fileNameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_metadata_file_name_not_blank',
    entity: 'fileMetadata',
    table: 'file_metadata',
    field: 'fileName',
    code: 'file_metadata.file_name.not_blank',
    message: 'Имя файла не может быть пустым',
  ),
  FileMetadataConstraint.fileSizeNonNegative.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_metadata_file_size_non_negative',
    entity: 'fileMetadata',
    table: 'file_metadata',
    field: 'fileSize',
    code: 'file_metadata.size.negative',
    message: 'Размер файла не может быть отрицательным',
  ),
  FileMetadataConstraint.sha256Length.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_metadata_sha256_length',
    entity: 'fileMetadata',
    table: 'file_metadata',
    field: 'sha256',
    code: 'file_metadata.sha256.invalid_length',
    message: 'Некорректная длина SHA-256 хеша',
  ),
  FileMetadataConstraint.integrityRequiresAvailable.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_file_metadata_integrity_requires_available',
    entity: 'fileMetadata',
    table: 'file_metadata',
    field: 'integrityStatus',
    code: 'file_metadata.integrity.available_required',
    message: 'Проверка целостности возможна только для доступных файлов',
  ),
};
