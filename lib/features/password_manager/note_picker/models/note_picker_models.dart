/// Результат выбора заметки
class NotePickerResult {
  final String id;
  final String name;

  const NotePickerResult({required this.id, required this.name});
}

/// Результат выбора нескольких заметок
class NotePickerMultiResult {
  final List<NotePickerResult> notes;

  const NotePickerMultiResult({this.notes = const []});

  bool get isEmpty => notes.isEmpty;
  bool get isNotEmpty => notes.isNotEmpty;
  int get length => notes.length;
}

/// Состояние данных заметок
class NotePickerData {
  final List<dynamic> notes;
  final bool hasMore;
  final bool isLoadingMore;
  final String? excludeNoteId;

  const NotePickerData({
    this.notes = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.excludeNoteId,
  });

  NotePickerData copyWith({
    List<dynamic>? notes,
    bool? hasMore,
    bool? isLoadingMore,
    String? excludeNoteId,
  }) {
    return NotePickerData(
      notes: notes ?? this.notes,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      excludeNoteId: excludeNoteId ?? this.excludeNoteId,
    );
  }
}
