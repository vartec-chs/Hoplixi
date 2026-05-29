import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../dto/system/category_dto.dart';

extension CategoryDataMapper on CategoriesData {
  CategoryViewDto toCategoryViewDto() {
    return CategoryViewDto(
      id: id,
      name: name,
      iconRefId: iconRefId,
      color: color,
      parentId: parentId,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  CategoryCardDto toCategoryCardDto() {
    return CategoryCardDto(
      id: id,
      name: name,
      iconRefId: iconRefId,
      color: color,
      parentId: parentId,
    );
  }
}
