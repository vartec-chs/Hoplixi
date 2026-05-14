import 'package:hoplixi/main_db/core/models/dto/note_dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

extension NoteItemsDataMapper on NoteItemsData {
  NoteDataDto toNoteDataDto() {
    return NoteDataDto(
      deltaJson: deltaJson,
      content: content,
    );
  }

  NoteCardDataDto toNoteCardDataDto() {
    return NoteCardDataDto(
      content: content,
    );
  }
}
