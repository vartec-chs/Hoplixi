import 'dropbox_file.dart';

/// Dropbox 폴더 내용을 나타내는 클래스입니다.
class DropboxFolderContents {
  final List<DropboxFile> entries;
  final String? cursor;
  final bool hasMore;

  DropboxFolderContents({
    required this.entries,
    this.cursor,
    required this.hasMore,
  });

  factory DropboxFolderContents.fromJson(Map<String, dynamic> json) {
    return DropboxFolderContents(
      entries: (json['entries'] as List)
          .map((e) => DropboxFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      cursor: json['cursor'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }
}
