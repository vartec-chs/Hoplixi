class CloudResourceMetadata {
  const CloudResourceMetadata({
    this.sizeBytes,
    this.mimeType,
    this.createdAt,
    this.modifiedAt,
    this.hash,
    this.raw = const <String, dynamic>{},
  });

  final int? sizeBytes;
  final String? mimeType;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final String? hash;
  final Map<String, dynamic> raw;
}
