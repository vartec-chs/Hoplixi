import 'dart:convert';

class IconPackEntry {
  const IconPackEntry({
    required this.key,
    required this.packKey,
    required this.packName,
    required this.iconKey,
    required this.name,
    required this.relativePath,
    required this.svgPath,
    required this.importedAt,
  });

  final String key;
  final String packKey;
  final String packName;
  final String iconKey;
  final String name;
  final String relativePath;
  final String svgPath;
  final DateTime importedAt;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'packKey': packKey,
      'packName': packName,
      'iconKey': iconKey,
      'name': name,
      'relativePath': relativePath,
      'svgPath': svgPath,
      'importedAt': importedAt.toUtc().toIso8601String(),
    };
  }

  factory IconPackEntry.fromJson(Map<String, dynamic> json) {
    return IconPackEntry(
      key: json['key'] as String? ?? '',
      packKey: json['packKey'] as String? ?? '',
      packName: json['packName'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      svgPath: json['svgPath'] as String? ?? '',
      importedAt: DateTime.parse(
        json['importedAt'] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
    );
  }

  factory IconPackEntry.fromJsonLine(String line) {
    return IconPackEntry.fromJson(jsonDecode(line) as Map<String, dynamic>);
  }

  String toJsonLine() => jsonEncode(toJson());
}
