import 'package:hoplixi/main_db/core/models/field_update.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../main_store.dart';
import '../../../models/dto/system/custom_icon_dto.dart';
import '../../../models/dto/system/icon_ref_dto.dart';
import '../../../models/mappers/system/custom_icon_mapper.dart';
import '../../../models/mappers/system/icon_ref_mapper.dart';

class IconRepository {
  final MainStore db;

  IconRepository(this.db);

  Future<String> createCustomIcon(CreateCustomIconDto dto) async {
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
  }

  Future<void> updateCustomIcon(PatchCustomIconDto dto) async {
    await db.customIconsDao.updateCustomIconById(
      dto.id,
      CustomIconsCompanion(
        name: dto.name.toRequiredValue(),
        format: dto.format.toRequiredValue(),
        data: dto.data.toRequiredValue(),
        modifiedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCustomIcon(String customIconId) {
    return db.customIconsDao.deleteCustomIconById(customIconId);
  }

  Future<CustomIconViewDto?> getCustomIcon(String customIconId) async {
    final row = await db.customIconsDao.getCustomIconById(customIconId);
    return row?.toCustomIconViewDto();
  }

  Future<List<CustomIconCardDto>> getCustomIcons() async {
    final rows = await db.customIconsDao.getAllCustomIcons();
    return rows.map((r) => r.toCustomIconCardDto()).toList();
  }

  Future<String> createIconRef(CreateIconRefDto dto) async {
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
  }

  Future<void> updateIconRef(PatchIconRefDto dto) async {
    await db.iconRefsDao.updateIconRefById(
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
  }

  Future<void> deleteIconRef(String iconRefId) {
    return db.iconRefsDao.deleteIconRefById(iconRefId);
  }

  Future<IconRefViewDto?> getIconRef(String iconRefId) async {
    final row = await db.iconRefsDao.getIconRefById(iconRefId);
    return row?.toIconRefViewDto();
  }

  Future<List<IconRefCardDto>> getIconRefs() async {
    final rows = await db.iconRefsDao.getAllIconRefs();
    return rows.map((r) => r.toIconRefCardDto()).toList();
  }
}
