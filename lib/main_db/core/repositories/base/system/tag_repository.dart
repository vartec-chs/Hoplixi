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

  Future<void> updateTag(UpdateTagDto dto) async {
    if (dto.name != null && dto.name!.trim().isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    await db.tagsDao.updateTagById(
      dto.id,
      TagsCompanion(
        name: dto.name != null ? drift.Value(dto.name!.trim()) : const drift.Value.absent(),
        color: dto.color != null ? drift.Value(dto.color!) : const drift.Value.absent(),
        type: dto.type != null ? drift.Value(dto.type!) : const drift.Value.absent(),
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
