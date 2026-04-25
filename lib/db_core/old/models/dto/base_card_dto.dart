abstract interface class BaseCardDto {
  String get id;
  bool get isFavorite;
  bool get isPinned;
  bool get isArchived;
  bool get isDeleted;
  int get usedCount;
  DateTime get modifiedAt;
}
