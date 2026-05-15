import 'dart:io';

void create(String path, String content) {
  final file = File('lib/main_db/core/' + path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content.trim() + '\n');
}

void main() {
  create('models/dto/system/category_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/categories.dart';
part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
sealed class CategoryDto with _\ {
  const factory CategoryDto({
    String? id,
    required String name,
    String? description,
    String? iconRefId,
    @Default('FFFFFFFF') String color,
    required CategoryType type,
    String? parentId,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _CategoryDto;

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/item_category_history_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/categories.dart';
part 'item_category_history_dto.freezed.dart';
part 'item_category_history_dto.g.dart';

@freezed
sealed class ItemCategoryHistoryDto with _\ {
  const factory ItemCategoryHistoryDto({
    String? id,
    String? snapshotId,
    String? itemId,
    String? categoryId,
    required String name,
    String? description,
    String? iconRefId,
    required String color,
    required CategoryType type,
    String? parentId,
    DateTime? categoryCreatedAt,
    DateTime? categoryModifiedAt,
    DateTime? snapshotCreatedAt,
  }) = _ItemCategoryHistoryDto;

  factory ItemCategoryHistoryDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/tag_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/tags.dart';
part 'tag_dto.freezed.dart';
part 'tag_dto.g.dart';

@freezed
sealed class TagDto with _\ {
  const factory TagDto({
    String? id,
    required String name,
    @Default('FFFFFFFF') String color,
    required TagType type,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _TagDto;

  factory TagDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/item_tag_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'item_tag_dto.freezed.dart';
part 'item_tag_dto.g.dart';

@freezed
sealed class ItemTagDto with _\ {
  const factory ItemTagDto({
    required String itemId,
    required String tagId,
    DateTime? createdAt,
  }) = _ItemTagDto;

  factory ItemTagDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/vault_item_tag_history_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/tags.dart';
part 'vault_item_tag_history_dto.freezed.dart';
part 'vault_item_tag_history_dto.g.dart';

@freezed
sealed class VaultItemTagHistoryDto with _\ {
  const factory VaultItemTagHistoryDto({
    String? id,
    String? snapshotId,
    String? itemId,
    String? snapshotTagId,
    String? originalTagId,
    required String name,
    required String color,
    required TagType type,
    DateTime? originalTagCreatedAt,
    DateTime? originalItemTagCreatedAt,
    DateTime? snapshotCreatedAt,
  }) = _VaultItemTagHistoryDto;

  factory VaultItemTagHistoryDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/store_meta_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'store_meta_dto.freezed.dart';
part 'store_meta_dto.g.dart';

@freezed
sealed class StoreMetaDto with _\ {
  const factory StoreMetaDto({
    @Default(1) int singletonId,
    String? id,
    required String name,
    String? description,
    required String passwordHash,
    required String salt,
  }) = _StoreMetaDto;

  factory StoreMetaDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/store_settings_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'store_settings_dto.freezed.dart';
part 'store_settings_dto.g.dart';

@freezed
sealed class StoreSettingsDto with _\ {
  const factory StoreSettingsDto({
    @Default(1) int singletonId,
    String? language,
    String? theme,
  }) = _StoreSettingsDto;

  factory StoreSettingsDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/item_link_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/item_link/item_links.dart';
part 'item_link_dto.freezed.dart';
part 'item_link_dto.g.dart';

@freezed
sealed class ItemLinkDto with _\ {
  const factory ItemLinkDto({
    String? id,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType linkType,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _ItemLinkDto;

  factory ItemLinkDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/item_link_history_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/item_link/item_links.dart';
part 'item_link_history_dto.freezed.dart';
part 'item_link_history_dto.g.dart';

@freezed
sealed class ItemLinkHistoryDto with _\ {
  const factory ItemLinkHistoryDto({
    String? id,
    String? snapshotId,
    String? originalLinkId,
    String? sourceItemId,
    String? targetItemId,
    required ItemLinkType linkType,
    DateTime? snapshotCreatedAt,
  }) = _ItemLinkHistoryDto;

  factory ItemLinkHistoryDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/custom_icon_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';
import '../../../tables/system/icons/custom_icons.dart';
import '../converters.dart';
part 'custom_icon_dto.freezed.dart';
part 'custom_icon_dto.g.dart';

@freezed
sealed class CustomIconDto with _\ {
  const factory CustomIconDto({
    String? id,
    required String name,
    required CustomIconFormat format,
    @Uint8ListBase64Converter() required Uint8List data,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _CustomIconDto;

  factory CustomIconDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('models/dto/system/icon_ref_dto.dart', '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/icons/icon_refs.dart';
part 'icon_ref_dto.freezed.dart';
part 'icon_ref_dto.g.dart';

@freezed
sealed class IconRefDto with _\ {
  const factory IconRefDto({
    String? id,
    required String reference,
    required IconRefType type,
  }) = _IconRefDto;

  factory IconRefDto.fromJson(Map<String, dynamic> json) => _\(json);
}
  ''');

  create('dao/system/system_dao.dart', '''
import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_category_history.dart';
import '../../tables/system/tags.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/vault_item_tag_history.dart';
import '../../tables/system/store/store_meta_table.dart';
import '../../tables/system/store/store_settings.dart';
import '../../tables/system/item_link/item_links.dart';
import '../../tables/system/item_link/item_link_history.dart';
import '../../tables/system/icons/custom_icons.dart';
import '../../tables/system/icons/icon_refs.dart';

part 'system_dao.g.dart';

@DriftAccessor(tables: [
  Categories,
  ItemCategoryHistory,
  Tags,
  ItemTags,
  VaultItemTagHistory,
  StoreMetaTable,
  StoreSettings,
  ItemLinks,
  ItemLinkHistory,
  CustomIcons,
  IconRefs,
])
class SystemDao extends DatabaseAccessor<MainStore> with _\ {
  SystemDao(super.db);
}
  ''');

  create('models/mappers/system/system_mapper.dart', '''
import '../../dto/system/category_dto.dart';
import '../../dto/system/item_category_history_dto.dart';
import '../../dto/system/tag_dto.dart';
import '../../dto/system/item_tag_dto.dart';
import '../../dto/system/vault_item_tag_history_dto.dart';
import '../../dto/system/store_meta_dto.dart';
import '../../dto/system/store_settings_dto.dart';
import '../../dto/system/item_link_dto.dart';
import '../../dto/system/item_link_history_dto.dart';
import '../../dto/system/custom_icon_dto.dart';
import '../../dto/system/icon_ref_dto.dart';
import '../../../main_store.dart';

// Since the fields match roughly, we can provide basic mappers.
// To keep the implementation short as requested, here is a skeleton.

class SystemMapper {
  static CategoryDto mapCategory(CategoriesData entity) {
    return CategoryDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      iconRefId: entity.iconRefId,
      color: entity.color,
      type: entity.type,
      parentId: entity.parentId,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
    );
  }

  // and similarly for others ...
}
  ''');

  print('Done creating DTOs, Mappers, and DAOs.');
}
