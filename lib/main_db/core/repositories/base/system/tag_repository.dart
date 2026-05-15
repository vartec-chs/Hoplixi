import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../main_store.dart';
import '../../../models/dto/system/tag_dto.dart';
import '../../../models/mappers/system/tag_mapper.dart';

class TagRepository {
  final MainStore db;

  TagRepository(this.db);

  Future<String> createTag(CreateTagDto dto) async {
    final name = dto.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.tagsDao.insertTag(
      TagsCompanion.insert(
        id: drift.Value(id),
        name: name,
        color: drift.Value(dto.color),
        type: dto.type,
        createdAt: drift.Value(now),
        modifiedAt: drift.Value(now),
      ),
    );

    return id;
  }

  Future<void> updateTag(PatchTagDto dto) async {
    if (dto.name is FieldUpdateSet<String>) {
      final name = (dto.name as FieldUpdateSet<String>).value;
      if (name != null && name.trim().isEmpty) {
        throw ArgumentError('Tag name cannot be empty');
      }
    }

    await db.tagsDao.updateTagById(
      dto.id,
      TagsCompanion(
        name: dto.name.toRequiredValue(),
        color: dto.color.toRequiredValue(),
        type: dto.type.toRequiredValue(),
        modifiedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTag(String tagId) {
    return db.tagsDao.deleteTagById(tagId);
  }

  Future<TagViewDto?> getTag(String tagId) async {
    final row = await db.tagsDao.getTagById(tagId);
    return row?.toTagViewDto();
  }

  Future<List<TagCardDto>> getAllTags() async {
    final rows = await db.tagsDao.getAllTags();
    return rows.map((r) => r.toTagCardDto()).toList();
  }

  Future<List<TagCardDto>> searchTags(String query) async {
    final rows = await db.tagsDao.searchTagsByName(query);
    return rows.map((r) => r.toTagCardDto()).toList();
  }

  Future<bool> existsTag(String tagId) {
    return db.tagsDao.existsTag(tagId);
  }
}
