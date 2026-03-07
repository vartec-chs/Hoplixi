/// Результат выбора файла
class FilePickerResult {
  final String id;
  final String name;

  const FilePickerResult({required this.id, required this.name});
}

/// Результат выбора нескольких файлов
class FilePickerMultiResult {
  final List<FilePickerResult> files;

  const FilePickerMultiResult({this.files = const []});

  bool get isEmpty => files.isEmpty;
  bool get isNotEmpty => files.isNotEmpty;
  int get length => files.length;
}

/// Состояние данных файлов
class FilePickerData {
  final List<dynamic> files;
  final bool hasMore;
  final bool isLoadingMore;
  final String? excludeFileId;

  const FilePickerData({
    this.files = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.excludeFileId,
  });

  FilePickerData copyWith({
    List<dynamic>? files,
    bool? hasMore,
    bool? isLoadingMore,
    String? excludeFileId,
  }) {
    return FilePickerData(
      files: files ?? this.files,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      excludeFileId: excludeFileId ?? this.excludeFileId,
    );
  }
}
