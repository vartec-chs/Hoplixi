import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/dao/api_key/api_key_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/bank_card/bank_card_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/note/note_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/password/password_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/vault_items/vault_snapshots_history_dao.dart';
import 'package:hoplixi/main_db/core/models/dto/api_key_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/models/dto/note_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/main_db/core/services/relations/snapshot_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_snapshots_history.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';

class VaultSnapshotWriter {
  VaultSnapshotWriter({
    required this.vaultSnapshotsHistoryDao,
    required this.snapshotRelationsService,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.noteHistoryDao,
    required this.bankCardHistoryDao,
  });

  final VaultSnapshotsHistoryDao vaultSnapshotsHistoryDao;
  final SnapshotRelationsService snapshotRelationsService;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final NoteHistoryDao noteHistoryDao;
  final BankCardHistoryDao bankCardHistoryDao;

  Future<String> writeSnapshot({
    required VaultItemType type,
    required Object view,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    return switch (type) {
      VaultItemType.apiKey => _writeApiKeySnapshot(
          view as ApiKeyViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.password => _writePasswordSnapshot(
          view as PasswordViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.note => _writeNoteSnapshot(
          view as NoteViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.bankCard => _writeBankCardSnapshot(
          view as BankCardViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      // TODO: Добавить остальные типы сущностей
      _ => throw UnsupportedError('Snapshot is not implemented for $type'),
    };
  }

  Future<String> _writeApiKeySnapshot(
    ApiKeyViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final apiKey = view.apiKey;
    final historyId = await _writeBaseSnapshot(item, action);

    await apiKeyHistoryDao.insertApiKeyHistory(
      ApiKeyHistoryCompanion.insert(
        historyId: historyId,
        service: apiKey.service,
        key: Value(includeSecrets ? apiKey.key : null),
        tokenType: Value(apiKey.tokenType),
        tokenTypeOther: Value(apiKey.tokenTypeOther),
        environment: Value(apiKey.environment),
        environmentOther: Value(apiKey.environmentOther),
        expiresAt: Value(apiKey.expiresAt),
        revoked: Value(apiKey.isRevoked),
        revokedAt: Value(apiKey.revokedAt),
        rotationPeriodDays: Value(apiKey.rotationPeriodDays),
        lastRotatedAt: Value(apiKey.lastRotatedAt),
        owner: Value(apiKey.owner),
        baseUrl: Value(apiKey.baseUrl),
        scopesText: Value(apiKey.scopesText),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writePasswordSnapshot(
    PasswordViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final password = view.password;
    final historyId = await _writeBaseSnapshot(item, action);

    await passwordHistoryDao.insertPasswordHistory(
      PasswordHistoryCompanion.insert(
        historyId: historyId,
        login: Value(password.login),
        email: Value(password.email),
        password: Value(includeSecrets ? password.password : null),
        url: Value(password.url),
        expiresAt: Value(password.expiresAt),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeNoteSnapshot(
    NoteViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final note = view.note;
    final historyId = await _writeBaseSnapshot(item, action);

    await noteHistoryDao.insertNoteHistory(
      NoteHistoryCompanion.insert(
        historyId: historyId,
        deltaJson: Value(includeSecrets ? note.deltaJson : null),
        content: Value(includeSecrets ? note.content : null),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeBankCardSnapshot(
    BankCardViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final bankCard = view.bankCard;
    final historyId = await _writeBaseSnapshot(item, action);

    await bankCardHistoryDao.insertBankCardHistory(
      BankCardHistoryCompanion.insert(
        historyId: historyId,
        cardholderName: Value(bankCard.cardholderName),
        cardNumber: Value(includeSecrets ? bankCard.cardNumber : null),
        cardType: Value(bankCard.cardType),
        cardTypeOther: Value(bankCard.cardTypeOther),
        cardNetwork: Value(bankCard.cardNetwork),
        cardNetworkOther: Value(bankCard.cardNetworkOther),
        expiryMonth: Value(bankCard.expiryMonth),
        expiryYear: Value(bankCard.expiryYear),
        cvv: Value(includeSecrets ? bankCard.cvv : null),
        bankName: Value(bankCard.bankName),
        accountNumber: Value(bankCard.accountNumber),
        routingNumber: Value(bankCard.routingNumber),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeBaseSnapshot(
    VaultItemViewDto item,
    VaultEventHistoryAction action,
  ) async {
    final historyId = const Uuid().v4();
    final now = DateTime.now();

    final categoryHistoryId = await snapshotRelationsService.snapshotCategoryForItem(
      categoryId: item.categoryId,
      itemId: item.itemId,
      snapshotId: historyId,
    );

    await vaultSnapshotsHistoryDao.insertVaultSnapshot(
      VaultSnapshotsHistoryCompanion.insert(
        id: Value(historyId),
        itemId: item.itemId,
        action: action,
        type: item.type,
        name: item.name,
        description: Value(item.description),
        categoryId: Value(item.categoryId),
        categoryHistoryId: Value(categoryHistoryId),
        iconRefId: Value(item.iconRefId),
        usedCount: Value(item.usedCount),
        isFavorite: Value(item.isFavorite),
        isArchived: Value(item.isArchived),
        isPinned: Value(item.isPinned),
        isDeleted: Value(item.isDeleted),
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
        lastUsedAt: Value(item.lastUsedAt),
        archivedAt: Value(item.archivedAt),
        deletedAt: Value(item.deletedAt),
        recentScore: Value(item.recentScore),
        historyCreatedAt: Value(now),
      ),
    );

    return historyId;
  }

  Future<void> _snapshotRelations(String historyId, String itemId) async {
    await snapshotRelationsService.snapshotTagsForItem(
      historyId: historyId,
      itemId: itemId,
    );

    await snapshotRelationsService.snapshotLinksForItem(
      historyId: historyId,
      itemId: itemId,
    );
  }
}
