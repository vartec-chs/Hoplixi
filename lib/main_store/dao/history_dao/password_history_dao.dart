import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/passwords_history.dart';

part 'password_history_dao.g.dart';

@DriftAccessor(tables: [PasswordsHistory])
class PasswordHistoryDao extends DatabaseAccessor<MainStore>
    with _$PasswordHistoryDaoMixin {
  PasswordHistoryDao(super.db);

  /// Получить всю историю паролей
  Future<List<PasswordsHistoryData>> getAllPasswordHistory() {
    return select(passwordsHistory).get();
  }

  /// Получить запись истории по ID
  Future<PasswordsHistoryData?> getPasswordHistoryById(String id) {
    return (select(
      passwordsHistory,
    )..where((ph) => ph.id.equals(id))).getSingleOrNull();
  }

  /// Получить историю паролей в виде карточек
  Future<List<PasswordHistoryCardDto>> getAllPasswordHistoryCards() {
    return (select(passwordsHistory)
          ..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)]))
        .map(
          (ph) => PasswordHistoryCardDto(
            id: ph.id,
            originalPasswordId: ph.originalPasswordId,
            action: ph.action.value,
            name: ph.name,
            actionAt: ph.actionAt,
          ),
        )
        .get();
  }

  /// Смотреть всю историю паролей с автообновлением
  Stream<List<PasswordsHistoryData>> watchAllPasswordHistory() {
    return (select(
      passwordsHistory,
    )..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)])).watch();
  }

  /// Смотреть историю паролей карточки с автообновлением
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryCards() {
    return (select(
      passwordsHistory,
    )..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)])).watch().map(
      (history) => history
          .map(
            (ph) => PasswordHistoryCardDto(
              id: ph.id,
              originalPasswordId: ph.originalPasswordId,
              action: ph.action.value,
              name: ph.name,
              actionAt: ph.actionAt,
            ),
          )
          .toList(),
    );
  }

  /// Получить историю для конкретного пароля
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryByOriginalId(
    String passwordId,
  ) {
    return (select(passwordsHistory)
          ..where((ph) => ph.originalPasswordId.equals(passwordId))
          ..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (ph) => PasswordHistoryCardDto(
                  id: ph.id,
                  originalPasswordId: ph.originalPasswordId,
                  action: ph.action.value,
                  name: ph.name,
                  actionAt: ph.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Получить историю по действию
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryByAction(
    String action,
  ) {
    return (select(passwordsHistory)
          ..where((ph) => ph.action.equals(action))
          ..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (ph) => PasswordHistoryCardDto(
                  id: ph.id,
                  originalPasswordId: ph.originalPasswordId,
                  action: ph.action.value,
                  name: ph.name,
                  actionAt: ph.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Создать запись истории
  Future<String> createPasswordHistory(CreatePasswordHistoryDto dto) {
    final companion = PasswordsHistoryCompanion.insert(
      originalPasswordId: dto.originalPasswordId,
      action: ActionInHistoryX.fromString(dto.action),
      name: dto.name,
      password: Value(dto.password),
      login: Value(dto.login),
      email: Value(dto.email),
      url: Value(dto.url),
      description: Value(dto.description),
      notes: Value(dto.notes),
      categoryName: Value(dto.categoryName),
      tags: Value(dto.tags),
      usedCount: Value(dto.usedCount ?? 0),
      isArchived: Value(dto.isArchived ?? false),
      isPinned: Value(dto.isPinned ?? false),
      isFavorite: Value(dto.isFavorite ?? false),
      lastUsedAt: Value(dto.lastAccessedAt),
      isDeleted: Value(dto.isDeleted ?? false),
      originalCreatedAt: Value(dto.originalCreatedAt),
      originalModifiedAt: Value(dto.originalModifiedAt),
    );
    return into(passwordsHistory).insert(companion).then((id) {
      return (select(passwordsHistory)
            ..where((ph) => ph.id.equals(id.toString())))
          .map((ph) => ph.id)
          .getSingle();
    });
  }

  /// Удалить историю для пароля
  Future<int> deletePasswordHistoryByPasswordId(String passwordId) {
    return (delete(
      passwordsHistory,
    )..where((ph) => ph.originalPasswordId.equals(passwordId))).go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldPasswordHistory(Duration olderThan) {
    final cutoffDate = DateTime.now().subtract(olderThan);
    return (delete(
      passwordsHistory,
    )..where((ph) => ph.actionAt.isSmallerThanValue(cutoffDate))).go();
  }

  // ============================================
  // Методы для пагинации и поиска
  // ============================================

  /// Получить историю по ID оригинального пароля с пагинацией и поиском
  Future<List<PasswordHistoryCardDto>> getPasswordHistoryCardsByOriginalId(
    String passwordId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    var query = select(passwordsHistory)
      ..where((ph) => ph.originalPasswordId.equals(passwordId))
      ..orderBy([(ph) => OrderingTerm.desc(ph.actionAt)])
      ..limit(limit, offset: offset);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          (ph) =>
              ph.name.like(search) |
              ph.login.like(search) |
              ph.email.like(search) |
              ph.url.like(search),
        );
    }

    final results = await query.get();
    return results
        .map(
          (ph) => PasswordHistoryCardDto(
            id: ph.id,
            originalPasswordId: ph.originalPasswordId,
            action: ph.action.value,
            name: ph.name,
            login: ph.login,
            email: ph.email,
            actionAt: ph.actionAt,
          ),
        )
        .toList();
  }

  /// Подсчитать количество записей истории для пароля
  Future<int> countPasswordHistoryByOriginalId(
    String passwordId,
    String? searchQuery,
  ) async {
    var query = selectOnly(passwordsHistory)
      ..addColumns([passwordsHistory.id.count()])
      ..where(passwordsHistory.originalPasswordId.equals(passwordId));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final search = '%$searchQuery%';
      query = query
        ..where(
          passwordsHistory.name.like(search) |
              passwordsHistory.login.like(search) |
              passwordsHistory.email.like(search) |
              passwordsHistory.url.like(search),
        );
    }

    final result = await query
        .map((row) => row.read(passwordsHistory.id.count()))
        .getSingle();
    return result ?? 0;
  }

  /// Удалить запись истории по ID
  Future<int> deletePasswordHistoryById(String historyId) {
    return (delete(
      passwordsHistory,
    )..where((ph) => ph.id.equals(historyId))).go();
  }
}
