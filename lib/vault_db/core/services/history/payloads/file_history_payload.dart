import '../../../tables/file/file_metadata.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class FileHistoryPayload extends HistoryPayload {
  const FileHistoryPayload({
    this.metadataId,
    this.metadataHistoryId,
    this.fileName,
    this.fileExtension,
    this.filePath,
    this.mimeType,
    this.fileSize,
    this.sha256,
    this.availabilityStatus,
    this.integrityStatus,
    this.missingDetectedAt,
    this.deletedAt,
    this.lastIntegrityCheckAt,
    this.snapshotCreatedAt,
  });

  final String? metadataId;
  final String? metadataHistoryId;
  final String? fileName;
  final String? fileExtension;
  final String? filePath;
  final String? mimeType;
  final int? fileSize;
  final String? sha256;
  final FileAvailabilityStatus? availabilityStatus;
  final FileIntegrityStatus? integrityStatus;
  final DateTime? missingDetectedAt;
  final DateTime? deletedAt;
  final DateTime? lastIntegrityCheckAt;
  final DateTime? snapshotCreatedAt;

  @override
  VaultItemType get type => VaultItemType.file;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'file.fileName',
        label: 'File name',
        value: fileName,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.fileExtension',
        label: 'File extension',
        value: fileExtension,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.filePath',
        label: 'File path',
        value: filePath,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.mimeType',
        label: 'MIME type',
        value: mimeType,
      ),
      HistoryFieldSnapshot<int>(
        key: 'file.fileSize',
        label: 'File size',
        value: fileSize,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.sha256',
        label: 'SHA256',
        value: sha256,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.availabilityStatus',
        label: 'Availability status',
        value: availabilityStatus?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'file.integrityStatus',
        label: 'Integrity status',
        value: integrityStatus?.name,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'file.missingDetectedAt',
        label: 'Missing detected at',
        value: missingDetectedAt,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'file.deletedAt',
        label: 'Deleted at',
        value: deletedAt,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'file.lastIntegrityCheckAt',
        label: 'Last integrity check at',
        value: lastIntegrityCheckAt,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'file.snapshotCreatedAt',
        label: 'Snapshot created at',
        value: snapshotCreatedAt,
      ),
    ];
  }
}
