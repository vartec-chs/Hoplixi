import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../dto/system/tag_dto.dart';

extension TagDataMapper on TagsData {
  TagViewDto toTagViewDto() {
    return TagViewDto(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  TagCardDto toTagCardDto() {
    return TagCardDto(id: id, name: name, color: color);
  }
}
