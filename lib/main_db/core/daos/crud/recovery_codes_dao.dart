import 'package:drift/drift.dart';

import 'package:hoplixi/main_db/core/daos/crud/crud_types.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/main_db/core/tables/recovery_codes/recovery_codes.dart';
import 'package:hoplixi/main_db/core/tables/recovery_codes/recovery_codes_items.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'recovery_codes_dao.g.dart';

@DriftAccessor(tables: [VaultItems, RecoveryCodesItems, RecoveryCodes])
class RecoveryCodesDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesDaoMixin {
  RecoveryCodesDao(super.db);

  // ---------------------------------------------------------------------------
  // Чтение
  // ---------------------------------------------------------------------------

  Future<List<VaultItemWith<RecoveryCodesItemsData>>>
  getAllRecoveryCodes() async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) =>
              (row.readTable(vaultItems), row.readTable(recoveryCodesItems)),
        )
        .toList();
  }

  Future<VaultItemWith<RecoveryCodesItemsData>?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(recoveryCodesItems));
  }

  Stream<List<VaultItemWith<RecoveryCodesItemsData>>> watchAllRecoveryCodes() {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                (row.readTable(vaultItems), row.readTable(recoveryCodesItems)),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Работа с отдельными кодами
  // ---------------------------------------------------------------------------

  /// Возвращает список кодов для элемента, отсортированных по позиции / id.
  Future<List<RecoveryCodeData>> getCodesForItem(String itemId) {
    return (select(recoveryCodes)
          ..where((c) => c.itemId.equals(itemId))
          ..orderBy([
            (c) => OrderingTerm.asc(c.position),
            (c) => OrderingTerm.asc(c.id),
          ]))
        .get();
  }

  /// Стрим кодов для элемента.
  Stream<List<RecoveryCodeData>> watchCodesForItem(String itemId) {
    return (select(recoveryCodes)
          ..where((c) => c.itemId.equals(itemId))
          ..orderBy([
            (c) => OrderingTerm.asc(c.position),
            (c) => OrderingTerm.asc(c.id),
          ]))
        .watch();
  }

  /// Пометить код как использованный.
  Future<bool> markCodeUsed(int codeId) async {
    final count =
        await (update(recoveryCodes)..where((c) => c.id.equals(codeId))).write(
          RecoveryCodesCompanion(
            used: const Value(true),
            usedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  /// Снять отметку об использовании кода.
  Future<bool> markCodeUnused(int codeId) async {
    final count =
        await (update(recoveryCodes)..where((c) => c.id.equals(codeId))).write(
          const RecoveryCodesCompanion(used: Value(false), usedAt: Value(null)),
        );
    return count > 0;
  }

  /// Удалить отдельный код.
  Future<bool> deleteCode(int codeId) async {
    final count = await (delete(
      recoveryCodes,
    )..where((c) => c.id.equals(codeId))).go();
    return count > 0;
  }

  /// Добавить отдельные коды к существующему элементу.
  Future<void> addCodes(String itemId, List<String> codes) {
    return db.transaction(() async {
      int position = await _nextPosition(itemId);
      for (final code in codes) {
        final trimmed = code.trim();
        if (trimmed.isEmpty) continue;
        await into(recoveryCodes).insert(
          RecoveryCodesCompanion.insert(
            itemId: itemId,
            code: trimmed,
            position: Value(position++),
          ),
        );
      }
    });
  }

  Future<int> _nextPosition(String itemId) async {
    final maxPos = recoveryCodes.position.max();
    final query = selectOnly(recoveryCodes)
      ..addColumns([maxPos])
      ..where(recoveryCodes.itemId.equals(itemId));
    final result = await query.map((row) => row.read(maxPos)).getSingle();
    return (result ?? -1) + 1;
  }

  // ---------------------------------------------------------------------------
  // Создание / обновление
  // ---------------------------------------------------------------------------

  Future<String> createRecoveryCodes(CreateRecoveryCodesDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.recoveryCodes,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(recoveryCodesItems).insert(
        RecoveryCodesItemsCompanion.insert(
          itemId: id,
          generatedAt: Value(dto.generatedAt),
          oneTime: Value(dto.oneTime ?? false),
          displayHint: Value(dto.displayHint),
        ),
      );

      // Вставляем отдельные коды
      if (dto.codes != null) {
        int pos = 0;
        for (final code in dto.codes!) {
          final trimmed = code.trim();
          if (trimmed.isEmpty) continue;
          await into(recoveryCodes).insert(
            RecoveryCodesCompanion.insert(
              itemId: id,
              code: trimmed,
              position: Value(pos++),
            ),
          );
        }
      }

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateRecoveryCodes(String id, UpdateRecoveryCodesDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isArchived: dto.isArchived != null
            ? Value(dto.isArchived!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );

      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      final itemCompanion = RecoveryCodesItemsCompanion(
        generatedAt: Value(dto.generatedAt),
        oneTime: dto.oneTime != null
            ? Value(dto.oneTime!)
            : const Value.absent(),
        displayHint: Value(dto.displayHint),
      );

      await (update(
        recoveryCodesItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      // Добавляем новые коды (если переданы)
      if (dto.newCodes != null && dto.newCodes!.isNotEmpty) {
        await addCodes(id, dto.newCodes!);
      }

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  // ---------------------------------------------------------------------------
  // Базовые методы интерфейса
  // ---------------------------------------------------------------------------
}
