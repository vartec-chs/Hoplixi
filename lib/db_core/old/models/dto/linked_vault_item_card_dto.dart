import 'package:hoplixi/db_core/old/models/dto/base_card_dto.dart';
import 'package:hoplixi/db_core/old/models/dto/category_dto.dart';
import 'package:hoplixi/db_core/old/models/dto/tag_dto.dart';
import 'package:hoplixi/db_core/old/models/enums/entity_types.dart';

class LinkedVaultItemCardDto implements BaseCardDto {
  const LinkedVaultItemCardDto({
    required this.id,
    required this.title,
    required this.vaultItemType,
    required this.isFavorite,
    required this.isPinned,
    required this.isArchived,
    required this.isDeleted,
    required this.usedCount,
    required this.modifiedAt,
    this.description,
    this.category,
    this.tags,
  });

  @override
  final String id;
  final String title;
  String get name => title;
  final String? description;
  final VaultItemType vaultItemType;
  @override
  final bool isFavorite;
  @override
  final bool isPinned;
  @override
  final bool isArchived;
  @override
  final bool isDeleted;
  @override
  final int usedCount;
  @override
  final DateTime modifiedAt;
  final CategoryInCardDto? category;
  final List<TagInCardDto>? tags;
}
