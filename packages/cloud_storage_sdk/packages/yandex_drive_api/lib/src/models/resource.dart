import 'resource_list.dart';

class Resource {
  String? publicKey;
  ResourceList? embedded;
  String? name;
  DateTime? created;
  Map<String, dynamic>? customProperties;
  String? publicUrl;
  DateTime? modified;
  String? path;
  String? type;
  String? mimeType;
  int? size;
  String? md5;
  String? preview;
  String? originPath;

  Resource({
    this.publicKey,
    this.embedded,
    this.name,
    this.created,
    this.customProperties,
    this.publicUrl,
    this.modified,
    this.path,
    this.type,
    this.mimeType,
    this.size,
    this.md5,
    this.preview,
    this.originPath,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      publicKey: json['public_key'],
      embedded: json['_embedded'] != null
          ? ResourceList.fromJson(json['_embedded'])
          : null,
      name: json['name'],
      created: json['created'] != null
          ? DateTime.parse(json['created']).toLocal()
          : null,
      customProperties: json['custom_properties'],
      publicUrl: json['public_url'],
      modified: json['modified'] != null
          ? DateTime.parse(json['modified']).toLocal()
          : null,
      path: json['path'],
      type: json['type'],
      mimeType: json['mime_type'],
      size: json['size'],
      md5: json['md5'],
      preview: json['preview'],
      originPath: json['origin_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_key': publicKey,
      '_embedded': embedded?.toJson(),
      'name': name,
      'created': created?.toUtc().toIso8601String(),
      'custom_properties': customProperties,
      'public_url': publicUrl,
      'modified': modified?.toUtc().toIso8601String(),
      'path': path,
      'type': type,
      'mime_type': mimeType,
      'size': size,
      'md5': md5,
      'preview': preview,
      'origin_path': originPath,
    };
  }
}
