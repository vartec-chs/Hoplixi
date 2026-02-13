import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/otp_tags.dart';
import 'package:hoplixi/main_store/tables/otps.dart';
import 'package:uuid/uuid.dart';

part 'otp_dao.g.dart';

@DriftAccessor(tables: [Otps, OtpsTags])
class OtpDao extends DatabaseAccessor<MainStore>
    with _$OtpDaoMixin
    implements BaseMainEntityDao {
  OtpDao(super.db);

  /// Получить все OTP
  Future<List<OtpsData>> getAllOtps() {
    return select(otps).get();
  }

  /// Получить OTP по ID
  Future<OtpsData?> getOtpById(String id) {
    return (select(otps)..where((o) => o.id.equals(id))).getSingleOrNull();
  }

  /// Получить OTP по ID пароля
  Future<OtpsData?> getOtpByPasswordId(String passwordId) {
    return (select(
      otps,
    )..where((o) => o.passwordId.equals(passwordId))).getSingleOrNull();
  }

  /// Получить список OTP по ID пароля (для проверки дубликатов)
  Future<List<OtpsData>> getOtpsByPasswordId(String passwordId) {
    return (select(otps)..where((o) => o.passwordId.equals(passwordId))).get();
  }

  /// Обновить привязку OTP к паролю
  Future<bool> updateOtpLink(String otpId, String? passwordId) async {
    final result = await (update(otps)..where((o) => o.id.equals(otpId))).write(
      OtpsCompanion(passwordId: Value(passwordId)),
    );
    return result > 0;
  }

  // toggle favorite
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  // toggle pin
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  // toggle archive
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isArchived: Value(isArchived)),
    );

    return result > 0;
  }

  /// Смотреть все OTP с автообновлением
  Stream<List<OtpsData>> watchAllOtps() {
    return (select(
      otps,
    )..orderBy([(o) => OrderingTerm.desc(o.modifiedAt)])).watch();
  }

  /// Удалить OTP (мягкое удаление)
  @override
  Future<bool> softDelete(String id) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      const OtpsCompanion(isDeleted: Value(true)),
    );
    return result > 0;
  }

  /// Восстановить OTP из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(otps)..where((o) => o.id.equals(id)))
        .write(const OtpsCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление OTP
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      otps,
    )..where((o) => o.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Создать новый OTP
  Future<String> createOtp(CreateOtpDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      final companion = OtpsCompanion.insert(
        id: Value(uuid),
        type: Value(OtpTypeX.fromString(dto.type)),
        secret: Uint8List.fromList(dto.secret),
        secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
        issuer: Value(dto.issuer),
        accountName: Value(dto.accountName),
        noteId: Value(dto.noteId),
        algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm ?? 'SHA1')),
        digits: Value(dto.digits ?? 6),
        period: Value(dto.period ?? 30),
        counter: Value(dto.counter),
        categoryId: Value(dto.categoryId),
        passwordId: Value(dto.passwordId),
      );
      await into(otps).insert(companion);
      await _insertOtpTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Создать множество OTP
  Future<List<String>> createManyOtps(List<CreateOtpDto> dtos) async {
    return await db.transaction(() async {
      final List<String> createdIds = [];
      for (final dto in dtos) {
        final uuid = const Uuid().v4();
        final companion = OtpsCompanion.insert(
          id: Value(uuid),
          type: Value(OtpTypeX.fromString(dto.type)),
          secret: Uint8List.fromList(dto.secret),
          secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
          issuer: Value(dto.issuer),
          accountName: Value(dto.accountName),
          noteId: Value(dto.noteId),
          algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm ?? 'SHA1')),
          digits: Value(dto.digits ?? 6),
          period: Value(dto.period ?? 30),
          counter: Value(dto.counter),
          categoryId: Value(dto.categoryId),
          passwordId: Value(dto.passwordId),
        );
        await into(otps).insert(companion);
        await _insertOtpTags(uuid, dto.tagsIds);
        createdIds.add(uuid);
      }
      return createdIds;
    });
  }

  /// Вставить теги для OTP
  Future<void> _insertOtpTags(String otpId, List<String>? tagIds) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.otpsTags)
          .insert(OtpsTagsCompanion.insert(otpId: otpId, tagId: tagId));
    }
  }

  /// Получить теги OTP по ID
  Future<List<String>> getOtpTagIds(String otpId) async {
    final rows = await (select(
      db.otpsTags,
    )..where((t) => t.otpId.equals(otpId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  /// Получить seкрет OTP по ID
  Future<Uint8List?> getOtpSecretById(String id) async {
    final qwery = (selectOnly(otps)..addColumns([otps.secret]))
      ..where(otps.id.equals(id));

    final result = await qwery.getSingleOrNull();
    return result?.read(otps.secret);
  }

  /// Увеличить счетчик использования и обновить метрики
  @override
  Future<bool> incrementUsage(String id) async {
    final otp = await getOtpById(id);
    if (otp == null) return false;

    final now = DateTime.now();
    final currentUsedCount = otp.usedCount + 1;

    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (otp.lastUsedAt != null && otp.recentScore != null) {
      final deltaSeconds = now.difference(otp.lastUsedAt!).inSeconds.toDouble();
      final tau = const Duration(
        days: 7,
      ).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = otp.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(
        usedCount: Value(currentUsedCount),
        recentScore: Value(newScore),
        lastUsedAt: Value(now),
      ),
    );

    return result > 0;
  }

  /// Синхронизировать теги OTP
  Future<void> syncOtpTags(String otpId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.otpsTags,
      )..where((t) => t.otpId.equals(otpId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(
          db.otpsTags,
        )..where((t) => t.otpId.equals(otpId) & t.tagId.isIn(toDelete))).go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.otpsTags)
            .insert(OtpsTagsCompanion.insert(otpId: otpId, tagId: tagId));
      }
    });
  }

  /// Обновить OTP
  Future<bool> updateOtp(String id, UpdateOtpDto dto) async {
    return await db.transaction(() async {
      final companion = OtpsCompanion(
        // Nullable поля - затираем при любом значении (включая null)
        issuer: Value(dto.issuer),
        accountName: Value(dto.accountName),
        noteId: Value(dto.noteId),
        counter: Value(dto.counter),
        categoryId: Value(dto.categoryId),
        passwordId: Value(dto.passwordId),
        // Поля с defaults - пропускаем если null
        algorithm: dto.algorithm != null
            ? Value(AlgorithmOtpX.fromString(dto.algorithm!))
            : const Value.absent(),
        digits: dto.digits != null ? Value(dto.digits!) : const Value.absent(),
        period: dto.period != null ? Value(dto.period!) : const Value.absent(),
        // Bool флаги - пропускаем если null
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );

      final result = await (update(
        otps,
      )..where((o) => o.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncOtpTags(id, dto.tagsIds!);
      }

      return result > 0;
    });
  }
}
