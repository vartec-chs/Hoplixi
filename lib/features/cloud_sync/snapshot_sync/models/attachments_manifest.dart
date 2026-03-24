class AttachmentManifestEntry {
  const AttachmentManifestEntry({
    required this.fileName,
    required this.size,
    required this.sha256,
    required this.updatedAt,
    this.deleted = false,
  });

  final String fileName;
  final int size;
  final String sha256;
  final DateTime updatedAt;
  final bool deleted;

  factory AttachmentManifestEntry.fromJson(Map<String, dynamic> json) {
    return AttachmentManifestEntry(
      fileName: (json['fileName'] as String?)?.trim() ?? '',
      size: _toInt(json['size']),
      sha256: (json['sha256'] as String?)?.trim() ?? '',
      updatedAt:
          _tryParseDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'size': size,
      'sha256': sha256,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deleted': deleted,
    };
  }
}

class AttachmentsManifest {
  const AttachmentsManifest({
    required this.version,
    required this.storeUuid,
    required this.revision,
    required this.updatedAt,
    required this.filesHash,
    required this.files,
  });

  final int version;
  final String storeUuid;
  final int revision;
  final DateTime updatedAt;
  final String filesHash;
  final List<AttachmentManifestEntry> files;

  factory AttachmentsManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return AttachmentsManifest(
      version: _toInt(json['version'], fallback: 1),
      storeUuid: (json['storeUuid'] as String?)?.trim() ?? '',
      revision: _toInt(json['revision']),
      updatedAt:
          _tryParseDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      filesHash: (json['filesHash'] as String?)?.trim() ?? '',
      files: rawFiles is List
          ? rawFiles
                .whereType<Map>()
                .map(
                  (entry) => AttachmentManifestEntry.fromJson(
                    entry.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList(growable: false)
          : const <AttachmentManifestEntry>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'storeUuid': storeUuid,
      'revision': revision,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'filesHash': filesHash,
      'files': files.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

DateTime? _tryParseDateTime(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw)?.toUtc();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  return null;
}

int _toInt(Object? raw, {int fallback = 0}) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw) ?? fallback;
  }
  return fallback;
}
