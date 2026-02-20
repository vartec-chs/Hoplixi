import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/otp_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'otp_dao.g.dart';

@DriftAccessor(tables: [VaultItems, OtpItems])
class OtpDao extends DatabaseAccessor<MainStore> with _$OtpDaoMixin {
  OtpDao(super.db);

  /// Получить все OTP (JOIN)
  Future<List<(VaultItemsData, OtpItemsData)>> getAllOtps() async {
    final query = select(
      vaultItems,
    ).join([innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id))]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(otpItems)))
        .toList();
  }

  /// Получить OTP по ID
  Future<(VaultItemsData, OtpItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(otpItems));
  }

  /// Получить OTP по ID пароля
  Future<(VaultItemsData, OtpItemsData)?> getByPasswordItemId(
    String passwordItemId,
  ) async {
    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
    ])..where(otpItems.passwordItemId.equals(passwordItemId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(otpItems));
  }

  /// Обновить привязку OTP к паролю
  Future<bool> updateOtpLink(String otpId, String? passwordId) async {
    final result =
        await (update(otpItems)..where((o) => o.itemId.equals(otpId))).write(
          OtpItemsCompanion(passwordItemId: Value(passwordId)),
        );
    return result > 0;
  }

  /// Смотреть все OTP
  Stream<List<(VaultItemsData, OtpItemsData)>> watchAllOtps() {
    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(otpItems)))
          .toList(),
    );
  }

  /// Создать новый OTP
  Future<String> createOtp(CreateOtpDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.otp,
          name: dto.issuer ?? dto.accountName ?? 'OTP',
          description: const Value(null),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(otpItems).insert(
        OtpItemsCompanion.insert(
          itemId: uuid,
          type: Value(OtpTypeX.fromString(dto.type)),
          secret: Uint8List.fromList(dto.secret),
          secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
          issuer: Value(dto.issuer),
          accountName: Value(dto.accountName),
          algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm ?? 'SHA1')),
          digits: Value(dto.digits ?? 6),
          period: Value(dto.period ?? 30),
          counter: Value(dto.counter),
          passwordItemId: Value(dto.passwordId),
        ),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Создать множество OTP
  Future<List<String>> createManyOtps(List<CreateOtpDto> dtos) {
    return db.transaction(() async {
      final ids = <String>[];
      for (final dto in dtos) {
        final id = await createOtp(dto);
        ids.add(id);
      }
      return ids;
    });
  }

  /// Получить секрет OTP
  Future<Uint8List?> getOtpSecretById(String id) async {
    final query = (selectOnly(otpItems)..addColumns([otpItems.secret]))
      ..where(otpItems.itemId.equals(id));
    final result = await query.getSingleOrNull();
    return result?.read(otpItems.secret);
  }

  /// Обновить OTP
  Future<bool> updateOtp(String id, UpdateOtpDto dto) {
    return db.transaction(() async {
      // vault_items
      final vaultCompanion = VaultItemsCompanion(
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );
      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      // otp_items
      final otpCompanion = OtpItemsCompanion(
        issuer: Value(dto.issuer),
        accountName: Value(dto.accountName),
        counter: Value(dto.counter),
        passwordItemId: Value(dto.passwordId),
        algorithm: dto.algorithm != null
            ? Value(AlgorithmOtpX.fromString(dto.algorithm!))
            : const Value.absent(),
        digits: dto.digits != null ? Value(dto.digits!) : const Value.absent(),
        period: dto.period != null ? Value(dto.period!) : const Value.absent(),
      );
      await (update(
        otpItems,
      )..where((o) => o.itemId.equals(id))).write(otpCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      return true;
    });
  }
}
