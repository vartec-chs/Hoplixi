import 'gd_file.dart';

class FileListResponse {
  List<GDFile>? files;
  bool? incompleteSearch;
  String? nextPageToken;

  FileListResponse({this.files, this.incompleteSearch, this.nextPageToken});

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    return FileListResponse(
      files:
          (json['files'] as List?)
              ?.map((value) => GDFile.fromJson(value as Map<String, dynamic>))
              .toList(),
      incompleteSearch: json['incompleteSearch'] as bool?,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (files != null) 'files': files!.map((file) => file.toJson()).toList(),
    'incompleteSearch': ?incompleteSearch,
    'nextPageToken': ?nextPageToken,
  };
}
