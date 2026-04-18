part of 'history_repository.dart';

extension _HistoryRepositoryLoadersPrimary on HistoryRepository {
  Future<List<_HistorySnapshot>> _loadSnapshots(
    EntityType entityType,
    String originalEntityId,
  ) {
    switch (entityType) {
      case EntityType.password:
        return _loadPasswordHistory(originalEntityId);
      case EntityType.note:
        return _loadNoteHistory(originalEntityId);
      case EntityType.bankCard:
        return _loadBankCardHistory(originalEntityId);
      case EntityType.file:
        return _loadFileHistory(originalEntityId);
      case EntityType.otp:
        return _loadOtpHistory(originalEntityId);
      case EntityType.document:
        return _loadDocumentHistory(originalEntityId);
      case EntityType.contact:
      case EntityType.apiKey:
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
      case EntityType.loyaltyCard:
        return _loadSnapshotsSecondary(entityType, originalEntityId);
    }
  }

  Future<_HistorySnapshot?> _loadCurrentSnapshot(
    EntityType entityType,
    String originalEntityId,
  ) {
    switch (entityType) {
      case EntityType.password:
        return _loadCurrentPassword(originalEntityId);
      case EntityType.note:
        return _loadCurrentNote(originalEntityId);
      case EntityType.bankCard:
        return _loadCurrentBankCard(originalEntityId);
      case EntityType.file:
        return _loadCurrentFile(originalEntityId);
      case EntityType.otp:
        return _loadCurrentOtp(originalEntityId);
      case EntityType.document:
        return _loadCurrentDocument(originalEntityId);
      case EntityType.contact:
      case EntityType.apiKey:
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
      case EntityType.loyaltyCard:
        return _loadCurrentSnapshotSecondary(entityType, originalEntityId);
    }
  }

  Future<Map<String, List<HistoryCustomFieldValue>>> _loadHistoryCustomFields(
    Iterable<String> historyIds,
  ) async {
    final result = <String, List<HistoryCustomFieldValue>>{};
    for (final historyId in historyIds) {
      final rows = await store.customFieldHistoryDao.getByHistoryId(historyId);
      result[historyId] = rows
          .map(
            (row) => HistoryCustomFieldValue(
              key: '${row.sortOrder}:${row.label}',
              label: row.label,
              value: row.value,
              fieldType: row.fieldType,
              sortOrder: row.sortOrder,
            ),
          )
          .toList();
    }
    return result;
  }

  Future<List<HistoryCustomFieldValue>> _loadLiveCustomFields(
    String itemId,
  ) async {
    final rows = await store.customFieldDao.getByItemId(itemId);
    return rows
        .map(
          (row) => HistoryCustomFieldValue(
            key: '${row.sortOrder}:${row.label}',
            label: row.label,
            value: row.value,
            fieldType: row.fieldType,
            sortOrder: row.sortOrder,
          ),
        )
        .toList();
  }

  _HistorySnapshot _baseSnapshot({
    required EntityType entityType,
    required String revisionId,
    required String originalEntityId,
    required String action,
    required DateTime actionAt,
    required String title,
    required String? subtitle,
    required String? description,
    required String? categoryId,
    String? categoryName,
    required Map<String, Object?> fields,
    required Set<String> sensitiveKeys,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required double? recentScore,
    required DateTime? lastUsedAt,
    required DateTime? originalCreatedAt,
    required DateTime? originalModifiedAt,
    required List<HistoryCustomFieldValue> customFields,
    required List<String> restoreWarnings,
    required bool isRestorable,
  }) {
    return _HistorySnapshot(
      entityType: entityType,
      revisionId: revisionId,
      originalEntityId: originalEntityId,
      action: action,
      actionAt: actionAt,
      title: title,
      subtitle: subtitle,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      fields: fields,
      sensitiveKeys: sensitiveKeys,
      usedCount: usedCount,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isPinned: isPinned,
      isDeleted: isDeleted,
      recentScore: recentScore,
      lastUsedAt: lastUsedAt,
      originalCreatedAt: originalCreatedAt,
      originalModifiedAt: originalModifiedAt,
      customFields: customFields,
      restoreWarnings: restoreWarnings,
      isRestorable: isRestorable,
    );
  }

  Future<_HistorySnapshot?> _loadCurrentPassword(String id) async {
    final row = await store.passwordDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.password,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.login ?? item.email,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'login': item.login,
        'email': item.email,
        'password': item.password,
        'url': item.url,
        'expireAt': item.expireAt,
      },
      sensitiveKeys: const {'password'},
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: _genericWarnings(),
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadPasswordHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.passwordHistory,
              store.passwordHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.password),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.passwordHistory);
      return _baseSnapshot(
        entityType: EntityType.password,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.login ?? item.email,
        description: vault.description,
        categoryId: vault.categoryId,
        categoryName: vault.categoryName,
        fields: {
          'name': vault.name,
          'description': vault.description,
          'category': vault.categoryName,
          'usedCount': vault.usedCount,
          'favorite': vault.isFavorite,
          'archived': vault.isArchived,
          'pinned': vault.isPinned,
          'deleted': vault.isDeleted,
          'login': item.login,
          'email': item.email,
          'password': item.password,
          'url': item.url,
          'expireAt': null,
        },
        sensitiveKeys: const {'password'},
        usedCount: vault.usedCount,
        isFavorite: vault.isFavorite,
        isArchived: vault.isArchived,
        isPinned: vault.isPinned,
        isDeleted: vault.isDeleted,
        recentScore: vault.recentScore,
        lastUsedAt: vault.lastUsedAt,
        originalCreatedAt: vault.originalCreatedAt,
        originalModifiedAt: vault.originalModifiedAt,
        customFields: historyFields[vault.id] ?? const [],
        restoreWarnings: _genericWarnings(),
        isRestorable: true,
      );
    }).toList();
  }

  Future<_HistorySnapshot?> _loadCurrentNote(String id) async {
    final row = await store.noteDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.note,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.content,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'content': item.content,
        'deltaJson': item.deltaJson,
      },
      sensitiveKeys: const {},
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: _genericWarnings(),
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadNoteHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.noteHistory,
              store.noteHistory.historyId.equalsExp(store.vaultItemHistory.id),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.note),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.noteHistory);
      return _baseSnapshot(
        entityType: EntityType.note,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.content,
        description: vault.description,
        categoryId: vault.categoryId,
        categoryName: vault.categoryName,
        fields: {
          'name': vault.name,
          'description': vault.description,
          'category': vault.categoryName,
          'usedCount': vault.usedCount,
          'favorite': vault.isFavorite,
          'archived': vault.isArchived,
          'pinned': vault.isPinned,
          'deleted': vault.isDeleted,
          'content': item.content,
          'deltaJson': item.deltaJson,
        },
        sensitiveKeys: const {},
        usedCount: vault.usedCount,
        isFavorite: vault.isFavorite,
        isArchived: vault.isArchived,
        isPinned: vault.isPinned,
        isDeleted: vault.isDeleted,
        recentScore: vault.recentScore,
        lastUsedAt: vault.lastUsedAt,
        originalCreatedAt: vault.originalCreatedAt,
        originalModifiedAt: vault.originalModifiedAt,
        customFields: historyFields[vault.id] ?? const [],
        restoreWarnings: _genericWarnings(),
        isRestorable: true,
      );
    }).toList();
  }
}

extension _HistoryRepositoryLoadersPrimaryMore on HistoryRepository {
  Future<_HistorySnapshot?> _loadCurrentBankCard(String id) async {
    final row = await store.bankCardDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.bankCard,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.cardholderName,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'cardholderName': item.cardholderName,
        'cardNumber': item.cardNumber,
        'cardType': item.cardType?.value,
        'cardNetwork': item.cardNetwork?.value,
        'expiryMonth': item.expiryMonth,
        'expiryYear': item.expiryYear,
        'cvv': item.cvv,
        'bankName': item.bankName,
        'accountNumber': item.accountNumber,
        'routingNumber': item.routingNumber,
      },
      sensitiveKeys: const {
        'cardNumber',
        'cvv',
        'accountNumber',
        'routingNumber',
      },
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: _genericWarnings(),
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadBankCardHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.bankCardHistory,
              store.bankCardHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.bankCard),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.bankCardHistory);
      return _baseSnapshot(
        entityType: EntityType.bankCard,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.cardholderName,
        description: vault.description,
        categoryId: vault.categoryId,
        categoryName: vault.categoryName,
        fields: {
          'name': vault.name,
          'description': vault.description,
          'category': vault.categoryName,
          'usedCount': vault.usedCount,
          'favorite': vault.isFavorite,
          'archived': vault.isArchived,
          'pinned': vault.isPinned,
          'deleted': vault.isDeleted,
          'cardholderName': item.cardholderName,
          'cardNumber': item.cardNumber,
          'cardType': item.cardType?.value,
          'cardNetwork': item.cardNetwork?.value,
          'expiryMonth': item.expiryMonth,
          'expiryYear': item.expiryYear,
          'cvv': item.cvv,
          'bankName': item.bankName,
          'accountNumber': item.accountNumber,
          'routingNumber': item.routingNumber,
        },
        sensitiveKeys: const {
          'cardNumber',
          'cvv',
          'accountNumber',
          'routingNumber',
        },
        usedCount: vault.usedCount,
        isFavorite: vault.isFavorite,
        isArchived: vault.isArchived,
        isPinned: vault.isPinned,
        isDeleted: vault.isDeleted,
        recentScore: vault.recentScore,
        lastUsedAt: vault.lastUsedAt,
        originalCreatedAt: vault.originalCreatedAt,
        originalModifiedAt: vault.originalModifiedAt,
        customFields: historyFields[vault.id] ?? const [],
        restoreWarnings: _genericWarnings(),
        isRestorable: true,
      );
    }).toList();
  }

  Future<_HistorySnapshot?> _loadCurrentFile(String id) async {
    final row = await store.fileDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    final metadata = item.metadataId == null
        ? null
        : await store.fileDao.getFileMetadataById(item.metadataId!);
    return _baseSnapshot(
      entityType: EntityType.file,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: metadata?.fileName,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'metadataId': item.metadataId,
        'fileName': metadata?.fileName,
        'fileExtension': metadata?.fileExtension,
        'mimeType': metadata?.mimeType,
        'fileSize': metadata?.fileSize,
        'filePath': metadata?.filePath,
      },
      sensitiveKeys: const {},
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: _genericWarnings(),
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadFileHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            leftOuterJoin(
              store.fileHistory,
              store.fileHistory.historyId.equalsExp(store.vaultItemHistory.id),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.file),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    final snapshots = <_HistorySnapshot>[];
    for (final row in rows) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTableOrNull(store.fileHistory);
      final metadata = item?.metadataId == null
          ? null
          : await store.fileDao.getFileMetadataById(item!.metadataId!);
      final canRestore =
          item?.metadataId != null &&
              metadata != null &&
              metadata.filePath != null
          ? await File(metadata.filePath!).exists()
          : false;
      snapshots.add(
        _baseSnapshot(
          entityType: EntityType.file,
          revisionId: vault.id,
          originalEntityId: vault.itemId,
          action: vault.action.value,
          actionAt: vault.actionAt,
          title: vault.name,
          subtitle: metadata?.fileName,
          description: vault.description,
          categoryId: vault.categoryId,
          categoryName: vault.categoryName,
          fields: {
            'name': vault.name,
            'description': vault.description,
            'category': vault.categoryName,
            'usedCount': vault.usedCount,
            'favorite': vault.isFavorite,
            'archived': vault.isArchived,
            'pinned': vault.isPinned,
            'deleted': vault.isDeleted,
            'metadataId': item?.metadataId,
            'fileName': metadata?.fileName,
            'fileExtension': metadata?.fileExtension,
            'mimeType': metadata?.mimeType,
            'fileSize': metadata?.fileSize,
            'filePath': metadata?.filePath,
          },
          sensitiveKeys: const {},
          usedCount: vault.usedCount,
          isFavorite: vault.isFavorite,
          isArchived: vault.isArchived,
          isPinned: vault.isPinned,
          isDeleted: vault.isDeleted,
          recentScore: vault.recentScore,
          lastUsedAt: vault.lastUsedAt,
          originalCreatedAt: vault.originalCreatedAt,
          originalModifiedAt: vault.originalModifiedAt,
          customFields: historyFields[vault.id] ?? const [],
          restoreWarnings: [
            ..._genericWarnings(),
            if (!canRestore) t.history.file_restore_unavailable,
          ],
          isRestorable: canRestore,
        ),
      );
    }
    return snapshots;
  }

  Future<_HistorySnapshot?> _loadCurrentOtp(String id) async {
    final row = await store.otpDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    final secret = await store.otpDao.getOtpSecretById(id);
    return _baseSnapshot(
      entityType: EntityType.otp,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.accountName ?? item.issuer,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'otpType': item.type.value,
        'issuer': item.issuer,
        'accountName': item.accountName,
        'secret': secret,
        'secretEncoding': item.secretEncoding.value,
        'algorithm': item.algorithm.value,
        'digits': item.digits,
        'period': item.period,
        'counter': item.counter,
        'passwordItemId': item.passwordItemId,
      },
      sensitiveKeys: const {'secret'},
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: _genericWarnings(),
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadOtpHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.otpHistory,
              store.otpHistory.historyId.equalsExp(store.vaultItemHistory.id),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.otp),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.otpHistory);
      return _baseSnapshot(
        entityType: EntityType.otp,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.accountName ?? item.issuer,
        description: vault.description,
        categoryId: vault.categoryId,
        categoryName: vault.categoryName,
        fields: {
          'name': vault.name,
          'description': vault.description,
          'category': vault.categoryName,
          'usedCount': vault.usedCount,
          'favorite': vault.isFavorite,
          'archived': vault.isArchived,
          'pinned': vault.isPinned,
          'deleted': vault.isDeleted,
          'otpType': item.type.value,
          'issuer': item.issuer,
          'accountName': item.accountName,
          'secret': item.secret,
          'secretEncoding': item.secretEncoding.value,
          'algorithm': item.algorithm.value,
          'digits': item.digits,
          'period': item.period,
          'counter': item.counter,
          'passwordItemId': item.passwordItemId,
        },
        sensitiveKeys: const {'secret'},
        usedCount: vault.usedCount,
        isFavorite: vault.isFavorite,
        isArchived: vault.isArchived,
        isPinned: vault.isPinned,
        isDeleted: vault.isDeleted,
        recentScore: vault.recentScore,
        lastUsedAt: vault.lastUsedAt,
        originalCreatedAt: vault.originalCreatedAt,
        originalModifiedAt: vault.originalModifiedAt,
        customFields: historyFields[vault.id] ?? const [],
        restoreWarnings: _genericWarnings(),
        isRestorable: true,
      );
    }).toList();
  }

  Future<_HistorySnapshot?> _loadCurrentDocument(String id) async {
    final row = await store.documentDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.document,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.documentType,
      description: vault.description,
      categoryId: vault.categoryId,
      fields: {
        'name': vault.name,
        'description': vault.description,
        'category': null,
        'usedCount': vault.usedCount,
        'favorite': vault.isFavorite,
        'archived': vault.isArchived,
        'pinned': vault.isPinned,
        'deleted': vault.isDeleted,
        'documentType': item.documentType,
        'aggregatedText': item.aggregatedText,
        'pageCount': item.pageCount,
      },
      sensitiveKeys: const {},
      usedCount: vault.usedCount,
      isFavorite: vault.isFavorite,
      isArchived: vault.isArchived,
      isPinned: vault.isPinned,
      isDeleted: vault.isDeleted,
      recentScore: vault.recentScore,
      lastUsedAt: vault.lastUsedAt,
      originalCreatedAt: vault.createdAt,
      originalModifiedAt: vault.modifiedAt,
      customFields: customFields,
      restoreWarnings: [
        ..._genericWarnings(),
        t.history.document_partial_restore,
      ],
      isRestorable: true,
    );
  }

  Future<List<_HistorySnapshot>> _loadDocumentHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.documentHistory,
              store.documentHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.document),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.documentHistory);
      return _baseSnapshot(
        entityType: EntityType.document,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.documentType,
        description: vault.description,
        categoryId: vault.categoryId,
        categoryName: vault.categoryName,
        fields: {
          'name': vault.name,
          'description': vault.description,
          'category': vault.categoryName,
          'usedCount': vault.usedCount,
          'favorite': vault.isFavorite,
          'archived': vault.isArchived,
          'pinned': vault.isPinned,
          'deleted': vault.isDeleted,
          'documentType': item.documentType,
          'aggregatedText': item.aggregatedText,
          'pageCount': item.pageCount,
        },
        sensitiveKeys: const {},
        usedCount: vault.usedCount,
        isFavorite: vault.isFavorite,
        isArchived: vault.isArchived,
        isPinned: vault.isPinned,
        isDeleted: vault.isDeleted,
        recentScore: vault.recentScore,
        lastUsedAt: vault.lastUsedAt,
        originalCreatedAt: vault.originalCreatedAt,
        originalModifiedAt: vault.originalModifiedAt,
        customFields: historyFields[vault.id] ?? const [],
        restoreWarnings: [
          ..._genericWarnings(),
          t.history.document_partial_restore,
        ],
        isRestorable: true,
      );
    }).toList();
  }
}
