import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/otp_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/otps_history.dart';

part 'otp_history_dao.g.dart';

@DriftAccessor(tables: [OtpsHistory])
class OtpHistoryDao extends DatabaseAccessor<MainStore>
    with _$OtpHistoryDaoMixin {
  OtpHistoryDao(super.db);

  /// Получить всю историю OTP
  Future<List<OtpsHistoryData>> getAllOtpHistory() {
    return select(otpsHistory).get();
  }

  /// Получить запись истории по ID
  Future<OtpsHistoryData?> getOtpHistoryById(String id) {
    return (select(
      otpsHistory,
    )..where((oh) => oh.id.equals(id))).getSingleOrNull();
  }

  /// Получить историю OTP в виде карточек
  Future<List<OtpHistoryCardDto>> getAllOtpHistoryCards() {
    return (select(otpsHistory)
          ..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)]))
        .map(
          (oh) => OtpHistoryCardDto(
            id: oh.id,
            originalOtpId: oh.originalOtpId,
            issuer: oh.issuer,
            accountName: oh.accountName,
            actionAt: oh.actionAt,
            action: oh.action.value,
            type: oh.type.value,
          ),
        )
        .get();
  }

  /// Смотреть всю историю OTP с автообновлением
  Stream<List<OtpsHistoryData>> watchAllOtpHistory() {
    return (select(
      otpsHistory,
    )..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)])).watch();
  }

  /// Смотреть историю OTP карточки с автообновлением
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryCards() {
    return (select(
      otpsHistory,
    )..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)])).watch().map(
      (history) => history
          .map(
            (oh) => OtpHistoryCardDto(
              id: oh.id,
              originalOtpId: oh.originalOtpId,
              issuer: oh.issuer,
              accountName: oh.accountName,
              actionAt: oh.actionAt,
              action: oh.action.value,
              type: oh.type.value,
            ),
          )
          .toList(),
    );
  }

  /// Получить историю для конкретного OTP
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryByOriginalId(String otpId) {
    return (select(otpsHistory)
          ..where((oh) => oh.originalOtpId.equals(otpId))
          ..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (oh) => OtpHistoryCardDto(
                  id: oh.id,
                  originalOtpId: oh.originalOtpId,
                  issuer: oh.issuer,
                  accountName: oh.accountName,
                  actionAt: oh.actionAt,
                  action: oh.action.value,
                  type: oh.type.value,
                ),
              )
              .toList(),
        );
  }

  /// Получить историю по действию
  Stream<List<OtpHistoryCardDto>> watchOtpHistoryByAction(String action) {
    return (select(otpsHistory)
          ..where((oh) => oh.action.equals(action))
          ..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (oh) => OtpHistoryCardDto(
                  id: oh.id,
                  originalOtpId: oh.originalOtpId,
                  issuer: oh.issuer,
                  accountName: oh.accountName,
                  actionAt: oh.actionAt,
                  action: oh.action.value,
                  type: oh.type.value,
                ),
              )
              .toList(),
        );
  }

  /// Создать запись истории
  Future<String> createOtpHistory(CreateOtpHistoryDto dto) {
    final companion = OtpsHistoryCompanion.insert(
      originalOtpId: dto.originalOtpId,
      action: ActionInHistoryX.fromString(dto.action),
      type: Value(OtpTypeX.fromString(dto.type)),
      secret: Uint8List.fromList(dto.secret),
      secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
      algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm)),
      issuer: Value(dto.issuer),
      accountName: Value(dto.accountName),
      noteId: Value(dto.noteId),
      digits: Value(dto.digits),
      period: Value(dto.period),
      counter: Value(dto.counter),
      categoryName: Value(dto.categoryName),
      usedCount: Value(dto.usedCount),
      isFavorite: Value(dto.isFavorite),
      isPinned: Value(dto.isPinned),
      originalCreatedAt: Value(dto.originalCreatedAt),
      originalModifiedAt: Value(dto.originalModifiedAt),
    );
    return into(otpsHistory).insert(companion).then((id) {
      return (select(otpsHistory)..where((oh) => oh.id.equals(id.toString())))
          .map((oh) => oh.id)
          .getSingle();
    });
  }

  /// Удалить историю для OTP
  Future<int> deleteOtpHistoryByOtpId(String otpId) {
    return (delete(
      otpsHistory,
    )..where((oh) => oh.originalOtpId.equals(otpId))).go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldOtpHistory(Duration olderThan) {
    final cutoffDate = DateTime.now().subtract(olderThan);
    return (delete(
      otpsHistory,
    )..where((oh) => oh.actionAt.isSmallerThanValue(cutoffDate))).go();
  }

  // ============================================
  // Методы для пагинации и поиска
  // ============================================

  /// Получить историю по ID оригинального OTP с пагинацией и поиском
  Future<List<OtpHistoryCardDto>> getOtpHistoryCardsByOriginalId(
    String otpId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    var query = select(otpsHistory)
      ..where((oh) => oh.originalOtpId.equals(otpId))
      ..orderBy([(oh) => OrderingTerm.desc(oh.actionAt)])
      ..limit(limit, offset: offset);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          (oh) =>
              oh.issuer.like(search) |
              oh.accountName.like(search) |
              oh.noteId.like(search),
        );
    }

    final results = await query.get();
    return results
        .map(
          (oh) => OtpHistoryCardDto(
            id: oh.id,
            originalOtpId: oh.originalOtpId,
            action: oh.action.value,
            issuer: oh.issuer,
            accountName: oh.accountName,
            type: oh.type.value,
            actionAt: oh.actionAt,
          ),
        )
        .toList();
  }

  /// Подсчитать количество записей истории для OTP
  Future<int> countOtpHistoryByOriginalId(
    String otpId,
    String? searchQuery,
  ) async {
    var query = selectOnly(otpsHistory)
      ..addColumns([otpsHistory.id.count()])
      ..where(otpsHistory.originalOtpId.equals(otpId));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          otpsHistory.issuer.like(search) |
              otpsHistory.accountName.like(search) |
              otpsHistory.noteId.like(search),
        );
    }

    final result = await query
        .map((row) => row.read(otpsHistory.id.count()))
        .getSingle();
    return result ?? 0;
  }

  /// Удалить запись истории по ID
  Future<int> deleteOtpHistoryById(String historyId) {
    return (delete(otpsHistory)..where((oh) => oh.id.equals(historyId))).go();
  }
}
