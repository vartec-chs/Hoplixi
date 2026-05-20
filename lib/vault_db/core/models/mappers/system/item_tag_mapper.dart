import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../dto/system/item_tag_dto.dart';

extension ItemTagDataMapper on ItemTagsData {
  ItemTagDto toItemTagDto() {
    return ItemTagDto(itemId: itemId, tagId: tagId, createdAt: createdAt);
  }
}
