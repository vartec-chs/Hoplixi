import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/bank_cards.dart';
import 'package:hoplixi/main_store/tables/bank_cards_tags.dart';
import 'package:uuid/uuid.dart';

part 'bank_card_dao.g.dart';

@DriftAccessor(tables: [BankCards, BankCardsTags])
class BankCardDao extends DatabaseAccessor<MainStore>
    with _$BankCardDaoMixin
    implements BaseMainEntityDao {
  BankCardDao(super.db);

  /// Получить все банковские карты
  Future<List<BankCardsData>> getAllBankCards() {
    return select(bankCards).get();
  }

  /// Получить карту по ID
  Future<BankCardsData?> getBankCardById(String id) {
    return (select(
      bankCards,
    )..where((bc) => bc.id.equals(id))).getSingleOrNull();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(bankCards)..where((b) => b.id.equals(id)))
        .write(BankCardsCompanion(isFavorite: Value(isFavorite)));

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(bankCards)..where((b) => b.id.equals(id)))
        .write(BankCardsCompanion(isPinned: Value(isPinned)));

    return result > 0;
  }

  /// Переключить архивирование
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(bankCards)..where((b) => b.id.equals(id)))
        .write(BankCardsCompanion(isArchived: Value(isArchived)));

    return result > 0;
  }

  /// Смотреть все карты с автообновлением
  Stream<List<BankCardsData>> watchAllBankCards() {
    return (select(
      bankCards,
    )..orderBy([(bc) => OrderingTerm.desc(bc.modifiedAt)])).watch();
  }

  /// Создать новую карту
  Future<String> createBankCard(CreateBankCardDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      final companion = BankCardsCompanion.insert(
        id: Value(uuid),
        name: dto.name,
        cardholderName: dto.cardholderName,
        cardNumber: dto.cardNumber,
        expiryMonth: dto.expiryMonth,
        expiryYear: dto.expiryYear,
        cardType: dto.cardType != null
            ? Value(CardTypeX.fromString(dto.cardType!))
            : const Value.absent(),
        cardNetwork: dto.cardNetwork != null
            ? Value(CardNetworkX.fromString(dto.cardNetwork!))
            : const Value.absent(),
        cvv: Value(dto.cvv),
        bankName: Value(dto.bankName),
        accountNumber: Value(dto.accountNumber),
        routingNumber: Value(dto.routingNumber),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
      );
      await into(bankCards).insert(companion);
      await _insertBankCardTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  Future<void> _insertBankCardTags(
    String bankCardId,
    List<String>? tagIds,
  ) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.bankCardsTags)
          .insert(
            BankCardsTagsCompanion.insert(cardId: bankCardId, tagId: tagId),
          );
    }
  }

  /// Увеличить счетчик использования и обновить метрики
  @override
  Future<bool> incrementUsage(String id) async {
    final card = await getBankCardById(id);
    if (card == null) return false;

    final now = DateTime.now();
    final currentUsedCount = card.usedCount + 1;

    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (card.lastUsedAt != null && card.recentScore != null) {
      final deltaSeconds = now
          .difference(card.lastUsedAt!)
          .inSeconds
          .toDouble();
      final tau = const Duration(days: 7).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = card.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(bankCards)..where((bc) => bc.id.equals(id)))
        .write(
          BankCardsCompanion(
            usedCount: Value(currentUsedCount),
            recentScore: Value(newScore),
            lastUsedAt: Value(now),
          ),
        );

    return result > 0;
  }

  /// Обновить карту
  Future<bool> updateBankCard(String id, UpdateBankCardDto dto) async {
    return await db.transaction(() async {
      final companion = BankCardsCompanion(
        // Обязательные поля - пропускаем если null
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        cardholderName: dto.cardholderName != null
            ? Value(dto.cardholderName!)
            : const Value.absent(),
        cardNumber: dto.cardNumber != null
            ? Value(dto.cardNumber!)
            : const Value.absent(),
        expiryMonth: dto.expiryMonth != null
            ? Value(dto.expiryMonth!)
            : const Value.absent(),
        expiryYear: dto.expiryYear != null
            ? Value(dto.expiryYear!)
            : const Value.absent(),
        // Nullable поля - затираем при любом значении (включая null)
        cardType: dto.cardType != null
            ? Value(CardTypeX.fromString(dto.cardType!))
            : const Value(null),
        cardNetwork: dto.cardNetwork != null
            ? Value(CardNetworkX.fromString(dto.cardNetwork!))
            : const Value(null),
        cvv: Value(dto.cvv),
        bankName: Value(dto.bankName),
        accountNumber: Value(dto.accountNumber),
        routingNumber: Value(dto.routingNumber),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
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

      final rowsAffected = await (update(
        bankCards,
      )..where((bc) => bc.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncBankCardTags(id, dto.tagsIds!);
      }

      return rowsAffected > 0;
    });
  }

  /// Мягкое удаление карты
  @override
  Future<bool> softDelete(String id) async {
    final rowsAffected =
        await (update(bankCards)..where((bc) => bc.id.equals(id))).write(
          const BankCardsCompanion(isDeleted: Value(true)),
        );
    return rowsAffected > 0;
  }

  /// Восстановить банковскую карту из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected =
        await (update(bankCards)..where((bc) => bc.id.equals(id))).write(
          const BankCardsCompanion(isDeleted: Value(false)),
        );
    return rowsAffected > 0;
  }

  /// Полное удаление банковскую карту
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      bankCards,
    )..where((bc) => bc.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить теги карты по ID
  Future<List<String>> getBankCardTagIds(String bankCardId) async {
    final rows = await (select(
      db.bankCardsTags,
    )..where((t) => t.cardId.equals(bankCardId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  /// Синхронизировать теги карты
  Future<void> syncBankCardTags(String bankCardId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.bankCardsTags,
      )..where((t) => t.cardId.equals(bankCardId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(db.bankCardsTags)..where(
              (t) => t.cardId.equals(bankCardId) & t.tagId.isIn(toDelete),
            ))
            .go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.bankCardsTags)
            .insert(
              BankCardsTagsCompanion.insert(cardId: bankCardId, tagId: tagId),
            );
      }
    });
  }
}
