import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/mappers/system/tag_mapper.dart';

class TagRepository {
  final VaultDB db;

  TagRepository(this.db);

  AsyncDbResult<String> createTag(CreateTagDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final name = dto.name.trim();
        if (name.isEmpty) {
          throw const DBCoreError.validation(
            code: 'tag.name_empty',
            message: 'Tag name cannot be empty',
          );
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
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании тега',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateTag(PatchTagDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (dto.name is FieldUpdateSet<String>) {
          final name = (dto.name as FieldUpdateSet<String>).value;
          if (name != null && name.trim().isEmpty) {
            throw const DBCoreError.validation(
              code: 'tag.name_empty',
              message: 'Tag name cannot be empty',
            );
          }
        }

        final count = await db.tagsDao.updateTagById(
          dto.id,
          TagsCompanion(
            name: dto.name.toRequiredValue(),
            color: dto.color.toRequiredValue(),
            modifiedAt: drift.Value(DateTime.now()),
          ),
        );

        if (count == 0) {
          throw DBCoreError.notFound(entity: 'tags', id: dto.id);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении тега',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteTag(String tagId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.tagsDao.deleteTagById(tagId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении тега',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<TagViewDto>> getTag(String tagId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final row = await db.tagsDao.getTagById(tagId);
        return Optional.fromNullable(row?.toTagViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении тега',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<TagCardDto>> getAllTags() {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.tagsDao.getAllTags();
        return rows.map((r) => r.toTagCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении всех тегов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<TagCardDto>> searchTags(String query) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.tagsDao.searchTagsByName(query);
        return rows.map((r) => r.toTagCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при поиске тегов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<bool> existsTag(String tagId) {
    return ResultUtils.tryCatchAsync(
      () => db.tagsDao.existsTag(tagId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при проверке существования тега',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
