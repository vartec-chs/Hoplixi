import 'dart:convert';

import 'icon_pack_summary.dart';

class IconPackManifest {
  const IconPackManifest({
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

  Map<String, dynamic> toJson() {
    return {
      'packKey': packKey,
      'displayName': displayName,
      'sourceArchiveName': sourceArchiveName,
      'importedAt': importedAt.toUtc().toIso8601String(),
      'iconCount': iconCount,
    };
  }

  factory IconPackManifest.fromJson(Map<String, dynamic> json) {
    return IconPackManifest(
      packKey: json['packKey'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      sourceArchiveName: json['sourceArchiveName'] as String? ?? '',
      importedAt: DateTime.parse(
        json['importedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      iconCount: json['iconCount'] as int? ?? 0,
    );
  }

  factory IconPackManifest.fromJsonString(String source) {
    return IconPackManifest.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  IconPackSummary toSummary() {
    return IconPackSummary(
      packKey: packKey,
      displayName: displayName,
      sourceArchiveName: sourceArchiveName,
      importedAt: importedAt,
      iconCount: iconCount,
    );
  }
}
