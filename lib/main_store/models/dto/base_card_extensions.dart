import 'package:hoplixi/main_store/models/dto/index.dart';

extension BaseCardDtoExtension on BaseCardDto {
  BaseCardDto copyWithBase({
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
  }) {
    final self = this;
    if (self is PasswordCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    } else if (self is NoteCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    } else if (self is BankCardCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    } else if (self is FileCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    } else if (self is OtpCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    }
    return self;
  }
}
