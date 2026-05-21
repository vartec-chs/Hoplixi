import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/system/custom_icon_dto.dart';
import '../../../models/dto/system/icon_ref_dto.dart';
import '../../../models/mappers/system/custom_icon_mapper.dart';
import '../../../models/mappers/system/icon_ref_mapper.dart';

class IconRepository {
  final VaultDB db;

  IconRepository(this.db);

  AsyncDbResult<String> createCustomIcon(CreateCustomIconDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final id = const Uuid().v4();
        final now = DateTime.now();

        await db.customIconsDao.insertCustomIcon(
          CustomIconsCompanion.insert(
            id: drift.Value(id),
            name: dto.name,
            format: dto.format,
            data: dto.data,
            createdAt: drift.Value(now),
            modifiedAt: drift.Value(now),
          ),
        );

        return id;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании пользовательской иконки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateCustomIcon(PatchCustomIconDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final count = await db.customIconsDao.updateCustomIconById(
          dto.id,
          CustomIconsCompanion(
            name: dto.name.toRequiredValue(),
            format: dto.format.toRequiredValue(),
            data: dto.data.toRequiredValue(),
            modifiedAt: drift.Value(DateTime.now()),
          ),
        );

        if (count == 0) {
          throw DBCoreError.notFound(entity: 'custom_icons', id: dto.id);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении пользовательской иконки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteCustomIcon(String customIconId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.customIconsDao.deleteCustomIconById(customIconId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении пользовательской иконки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<CustomIconViewDto>> getCustomIcon(String customIconId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final row = await db.customIconsDao.getCustomIconById(customIconId);
        return Optional.fromNullable(row?.toCustomIconViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении пользовательской иконки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<CustomIconCardDto>> getCustomIcons() {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.customIconsDao.getAllCustomIcons();
        return rows.map((r) => r.toCustomIconCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка пользовательских иконок',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<String> createIconRef(CreateIconRefDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final id = const Uuid().v4();
        final now = DateTime.now();

        await db.iconRefsDao.insertIconRef(
          IconRefsCompanion.insert(
            id: drift.Value(id),
            iconSourceType: dto.iconSourceType,
            iconPackId: drift.Value(dto.iconPackId),
            iconValue: drift.Value(dto.iconValue),
            customIconId: drift.Value(dto.customIconId),
            color: drift.Value(dto.color),
            backgroundColor: drift.Value(dto.backgroundColor),
            createdAt: drift.Value(now),
            modifiedAt: drift.Value(now),
          ),
        );

        return id;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании ссылки на иконку',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateIconRef(PatchIconRefDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final count = await db.iconRefsDao.updateIconRefById(
          dto.id,
          IconRefsCompanion(
            iconSourceType: dto.iconSourceType.toRequiredValue(),
            iconPackId: dto.iconPackId.toNullableValue(),
            iconValue: dto.iconValue.toNullableValue(),
            customIconId: dto.customIconId.toNullableValue(),
            color: dto.color.toNullableValue(),
            backgroundColor: dto.backgroundColor.toNullableValue(),
            modifiedAt: drift.Value(DateTime.now()),
          ),
        );

        if (count == 0) {
          throw DBCoreError.notFound(entity: 'icon_refs', id: dto.id);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении ссылки на иконку',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteIconRef(String iconRefId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.iconRefsDao.deleteIconRefById(iconRefId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении ссылки на иконку',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<IconRefViewDto>> getIconRef(String iconRefId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final row = await db.iconRefsDao.getIconRefById(iconRefId);
        return Optional.fromNullable(row?.toIconRefViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении ссылки на иконку',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<IconRefCardDto>> getIconRefs() {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.iconRefsDao.getAllIconRefs();
        return rows.map((r) => r.toIconRefCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка ссылок на иконки',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}

