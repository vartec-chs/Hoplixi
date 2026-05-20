import 'package:hoplixi/vault_db/core/models/dto/note_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension NoteItemsDataMapper on NoteItemsData {
  NoteDataDto toNoteDataDto() {
    return NoteDataDto(deltaJson: deltaJson, content: content);
  }

  NoteCardDataDto toNoteCardDataDto() {
    return NoteCardDataDto(content: content);
  }
}
