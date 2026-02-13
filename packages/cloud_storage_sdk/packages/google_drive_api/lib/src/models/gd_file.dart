class GDFile {
  DateTime? createdTime;
  String? driveId;
  bool? hasThumbnail;
  String? id;
  String? mimeType;
  DateTime? modifiedTime;
  String? name;
  List<String>? parents;
  String? size;

  GDFile({
    this.createdTime,
    this.driveId,
    this.hasThumbnail,
    this.id,
    this.mimeType,
    this.modifiedTime,
    this.name,
    this.parents,
    this.size,
  });

  factory GDFile.fromJson(Map<String, dynamic> json) {
    return GDFile(
      createdTime: json['createdTime'] != null
          ? DateTime.parse(json['createdTime']).toLocal()
          : null,
      driveId: json['driveId'],
      hasThumbnail: json['hasThumbnail'],
      id: json['id'],
      mimeType: json['mimeType'],
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime']).toLocal()
          : null,
      name: json['name'],
      parents: (json['parents'] as List?)?.map((e) => e.toString()).toList(),
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdTime': createdTime?.toUtc().toIso8601String(),
      'driveId': driveId,
      'hasThumbnail': hasThumbnail,
      'id': id,
      'mimeType': mimeType,
      'modifiedTime': modifiedTime?.toUtc().toIso8601String(),
      'name': name,
      'parents': parents,
      'size': size,
    };
  }
}
