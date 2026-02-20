import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/otp_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/otp_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'otp_history_dao.g.dart';

/// DAO для управления историей OTP.
///
/// Table-Per-Type: общие поля в [VaultItemHistory],
/// type-specific — в [OtpHistory].
@DriftAccessor(tables: [VaultItemHistory, OtpHistory])
class OtpHistoryDao extends DatabaseAccessor<MainStore>
    with _$OtpHistoryDaoMixin {
  OtpHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории OTP в виде карточек
  Future<List<OtpHistoryCardDto>> getAllOtpHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              otpHistory,
              otpHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.otp))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Смотреть всю историю OTP
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              otpHistory,
              otpHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.otp))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю для конкретного OTP
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryByOriginalId(String otpId) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              otpHistory,
              otpHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(otpId) &
                vaultItemHistory.type.equalsValue(VaultItemType.otp),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю по действию
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryByAction(String action) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              otpHistory,
              otpHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.otp),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю с пагинацией и поиском
  Future<List<OtpHistoryCardDto>> getOtpHistoryCardsByOriginalId(
    String otpId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        otpHistory,
        otpHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(otpId) &
        vaultItemHistory.type.equalsValue(VaultItemType.otp);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              otpHistory.issuer.like(q) |
              otpHistory.accountName.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей
  Future<int> countOtpHistoryByOriginalId(
    String otpId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          otpHistory,
          otpHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(otpId) &
            vaultItemHistory.type.equalsValue(VaultItemType.otp),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            otpHistory.issuer.like(q) |
            otpHistory.accountName.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории OTP
  Future<String> createOtpHistory(CreateOtpHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalOtpId,
        type: VaultItemType.otp,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.issuer ?? dto.accountName ?? '',
        categoryName: Value(dto.categoryName),
        usedCount: Value(dto.usedCount),
        isFavorite: Value(dto.isFavorite),
        isPinned: Value(dto.isPinned),
        originalCreatedAt: Value(dto.originalCreatedAt),
        originalModifiedAt: Value(dto.originalModifiedAt),
      );

      await into(vaultItemHistory).insert(companion);
      final historyId = companion.id.value;

      await into(otpHistory).insert(
        OtpHistoryCompanion.insert(
          historyId: historyId,
          type: Value(OtpTypeX.fromString(dto.type)),
          secret: Uint8List.fromList(dto.secret),
          secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
          algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm)),
          issuer: Value(dto.issuer),
          accountName: Value(dto.accountName),
          digits: Value(dto.digits),
          period: Value(dto.period),
          counter: Value(dto.counter),
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретного OTP
  Future<int> deleteOtpHistoryByOtpId(String otpId) {
    return (delete(vaultItemHistory)..where(
          (h) => h.itemId.equals(otpId) & h.type.equalsValue(VaultItemType.otp),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldOtpHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.otp),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deleteOtpHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  OtpHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final otp = row.readTable(otpHistory);

    return OtpHistoryCardDto(
      id: h.id,
      originalOtpId: h.itemId,
      action: h.action.value,
      issuer: otp.issuer,
      accountName: otp.accountName,
      type: otp.type.value,
      actionAt: h.actionAt,
    );
  }
}
