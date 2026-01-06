import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/tables/passwords.dart';
import 'package:uuid/uuid.dart';

part 'password_dao.g.dart';

@DriftAccessor(tables: [Passwords])
class PasswordDao extends DatabaseAccessor<MainStore>
    with _$PasswordDaoMixin
    implements BaseMainEntityDao {
  PasswordDao(super.db);

  /// Получить все пароли
  Future<List<PasswordsData>> getAllPasswords() async {
    final query = select(passwords);
    final results = await query.get();
    return results;
  }

  /// Получить пароль по ID
  Future<PasswordsData?> getPasswordById(String id) {
    return (select(passwords)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  // toggle favorite
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
 
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(PasswordsCompanion(isFavorite: Value(isFavorite)));

    return result > 0;
  }

  // toggle pin
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(PasswordsCompanion(isPinned: Value(isPinned)));

    return result > 0;
  }

  // toggle archive
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(PasswordsCompanion(isArchived: Value(isArchived)));

    return result > 0;
  }

  /// Смотреть все пароли с автообновлением
  Stream<List<PasswordsData>> watchAllPasswords() {
    return (select(
      passwords,
    )..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)])).watch();
  }

  /// Создать новый пароль
  Future<String> createPassword(CreatePasswordDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      // 1. Создаем запись пароля
      final companion = PasswordsCompanion.insert(
        id: Value(uuid),
        name: dto.name,
        password: dto.password,
        login: Value(dto.login),
        email: Value(dto.email),
        url: Value(dto.url),
        description: Value(dto.description),
        notes: Value(dto.notes),
        categoryId: Value(dto.categoryId),
      );

      await into(passwords).insert(companion);
      await _insertPasswordTags(uuid, dto.tagsIds);

      return uuid;
    });
  }

  Future<void> _insertPasswordTags(
    String passwordId,
    List<String>? tagIds,
  ) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.passwordsTags)
          .insert(
            PasswordsTagsCompanion.insert(passwordId: passwordId, tagId: tagId),
          );
    }
  }

  /// Обновить пароль
  Future<bool> updatePassword(String id, UpdatePasswordDto dto) async {
    return await db.transaction(() async {
      final companion = PasswordsCompanion(
        // Обязательные поля - пропускаем если null
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        password: dto.password != null
            ? Value(dto.password!)
            : const Value.absent(),
        // Nullable поля - затираем при любом значении (включая null)
        login: Value(dto.login),
        email: Value(dto.email),
        url: Value(dto.url),
        description: Value(dto.description),
        notes: Value(dto.notes),
        categoryId: Value(dto.categoryId),
        // Bool флаги - пропускаем если null
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

      final result = await (update(
        passwords,
      )..where((p) => p.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncPasswordTags(id, dto.tagsIds!);
      }

      return result > 0;
    });
  }

  Future<List<String>> getPasswordTagIds(String passwordId) async {
    final rows = await (select(
      db.passwordsTags,
    )..where((t) => t.passwordId.equals(passwordId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  Future<void> syncPasswordTags(String passwordId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.passwordsTags,
      )..where((t) => t.passwordId.equals(passwordId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(db.passwordsTags)..where(
              (t) => t.passwordId.equals(passwordId) & t.tagId.isIn(toDelete),
            ))
            .go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.passwordsTags)
            .insert(
              PasswordsTagsCompanion.insert(
                passwordId: passwordId,
                tagId: tagId,
              ),
            );
      }
    });
  }

  /// get only password filed
  Future<String?> getPasswordFieldById(String id) async {
    final query = selectOnly(passwords)
      ..addColumns([passwords.password])
      ..where(passwords.id.equals(id));
    final result = await query.getSingleOrNull();
    return result?.read(passwords.password);
  }

  /// Увеличить счетчик использования и обновить метрики
  Future<bool> incrementUsage(String id) async {
    final password = await getPasswordById(id);
    if (password == null) return false;

    final now = DateTime.now();
    final currentUsedCount = password.usedCount + 1;
    
    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (password.lastUsedAt != null && password.recentScore != null) {
      final deltaSeconds = now.difference(password.lastUsedAt!).inSeconds.toDouble();
      final tau = Duration(days: 7).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = password.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(PasswordsCompanion(
          usedCount: Value(currentUsedCount),
          recentScore: Value(newScore),
          lastUsedAt: Value(now),
        ));

    return result > 0;
  }

  /// Удалить пароль (мягкое удаление)
  @override
  Future<bool> softDelete(String id) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(const PasswordsCompanion(isDeleted: Value(true)));
    return result > 0;
  }

  /// Восстановить пароль из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(const PasswordsCompanion(isDeleted: Value(false)));
    return result > 0;
  }

  /// Полное удаление пароля
  @override
  Future<bool> permanentDelete(String id) async {
    final result = await (delete(
      passwords,
    )..where((p) => p.id.equals(id))).go();
    return result > 0;
  }
}
