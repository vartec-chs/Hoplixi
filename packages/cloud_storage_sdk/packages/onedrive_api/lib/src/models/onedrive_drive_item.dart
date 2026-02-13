/// OneDrive 드라이브 아이템(파일/폴더)을 나타내는 클래스입니다.
class OneDriveDriveItem {
  final String id;
  final String name;
  final String? description;
  final DateTime? createdDateTime;
  final DateTime? lastModifiedDateTime;
  final int? size;
  final String? webUrl;
  final String? downloadUrl;
  final String? parentReference;
  final Map<String, dynamic>? file;
  final Map<String, dynamic>? folder;

  OneDriveDriveItem({
    required this.id,
    required this.name,
    this.description,
    this.createdDateTime,
    this.lastModifiedDateTime,
    this.size,
    this.webUrl,
    this.downloadUrl,
    this.parentReference,
    this.file,
    this.folder,
  });

  factory OneDriveDriveItem.fromJson(Map<String, dynamic> json) {
    return OneDriveDriveItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdDateTime: json['createdDateTime'] != null
          ? DateTime.parse(json['createdDateTime'] as String)
          : null,
      lastModifiedDateTime: json['lastModifiedDateTime'] != null
          ? DateTime.parse(json['lastModifiedDateTime'] as String)
          : null,
      size: json['size'] as int?,
      webUrl: json['webUrl'] as String?,
      downloadUrl: json['@microsoft.graph.downloadUrl'] as String?,
      parentReference: json['parentReference']?['id'] as String?,
      file: json['file'] as Map<String, dynamic>?,
      folder: json['folder'] as Map<String, dynamic>?,
    );
  }

  /// 파일인지 확인합니다.
  bool get isFile => file != null;

  /// 폴더인지 확인합니다.
  bool get isFolder => folder != null;

  /// 파일 확장자를 가져옵니다.
  String? get fileExtension {
    if (!isFile) return null;
    final fileName = name;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return null;
    return fileName.substring(lastDotIndex + 1);
  }
}
