import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/tags.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<MainStore> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<int> insertTag(TagsCompanion companion) {
    return into(tags).insert(companion);
  }

  Future<int> updateTagById(String id, TagsCompanion companion) {
    return (update(tags)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<TagsData?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<TagsData>> getAllTags() {
    return select(tags).get();
  }

  Future<bool> existsTag(String id) async {
    final query = selectOnly(tags)
      ..addColumns([tags.id])
      ..where(tags.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> deleteTagById(String id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TagsData>> getTagsByType(TagType type) {
    return (select(tags)..where((t) => t.type.equals(type.name))).get();
  }

  Future<List<TagsData>> searchTagsByName(String query) {
    return (select(tags)..where((t) => t.name.contains(query))).get();
  }

  Future<List<TagsData>> getTagsByIds(List<String> ids) {
    return (select(tags)..where((t) => t.id.isIn(ids))).get();
  }
}
