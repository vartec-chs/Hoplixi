import '../../../main_store.dart';
import '../../dto/system/category_dto.dart';

extension CategoryDataMapper on CategoriesData {
  CategoryViewDto toCategoryViewDto() {
    return CategoryViewDto(
      id: id,
      name: name,
      description: description,
      iconRefId: iconRefId,
      color: color,
      type: type,
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
      type: type,
      parentId: parentId,
    );
  }
}
