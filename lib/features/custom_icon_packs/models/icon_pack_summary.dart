class IconPackSummary {
  const IconPackSummary({
    required this.packKey,
    required this.displayName,
    required this.sourceArchiveName,
    required this.importedAt,
    required this.iconCount,
  });

  final String packKey;
  final String displayName;
  final String sourceArchiveName;
  final DateTime importedAt;
  final int iconCount;
}
