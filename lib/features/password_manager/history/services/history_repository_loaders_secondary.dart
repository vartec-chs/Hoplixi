part of 'history_repository.dart';

extension _HistoryRepositoryLoadersSecondary on HistoryRepository {
  Future<List<_HistorySnapshot>> _loadSnapshotsSecondary(
    EntityType entityType,
    String id,
  ) {
    switch (entityType) {
      case EntityType.contact:
        return _loadContactHistory(id);
      case EntityType.apiKey:
        return _loadApiKeyHistory(id);
      case EntityType.sshKey:
        return _loadSshKeyHistory(id);
      case EntityType.certificate:
        return _loadCertificateHistory(id);
      case EntityType.cryptoWallet:
        return _loadCryptoWalletHistory(id);
      case EntityType.wifi:
        return _loadWifiHistory(id);
      case EntityType.identity:
        return _loadIdentityHistory(id);
      case EntityType.licenseKey:
        return _loadLicenseKeyHistory(id);
      case EntityType.recoveryCodes:
        return _loadRecoveryCodesHistory(id);
      case EntityType.loyaltyCard:
        return _loadLoyaltyCardHistory(id);
      case EntityType.password:
      case EntityType.note:
      case EntityType.bankCard:
      case EntityType.file:
      case EntityType.otp:
      case EntityType.document:
        throw UnimplementedError();
    }
  }

  Future<_HistorySnapshot?> _loadCurrentSnapshotSecondary(
    EntityType entityType,
    String id,
  ) {
    switch (entityType) {
      case EntityType.contact:
        return _loadCurrentContact(id);
      case EntityType.apiKey:
        return _loadCurrentApiKey(id);
      case EntityType.sshKey:
        return _loadCurrentSshKey(id);
      case EntityType.certificate:
        return _loadCurrentCertificate(id);
      case EntityType.cryptoWallet:
        return _loadCurrentCryptoWallet(id);
      case EntityType.wifi:
        return _loadCurrentWifi(id);
      case EntityType.identity:
        return _loadCurrentIdentity(id);
      case EntityType.licenseKey:
        return _loadCurrentLicenseKey(id);
      case EntityType.recoveryCodes:
        return _loadCurrentRecoveryCodes(id);
      case EntityType.loyaltyCard:
        return _loadCurrentLoyaltyCard(id);
      case EntityType.password:
      case EntityType.note:
      case EntityType.bankCard:
      case EntityType.file:
      case EntityType.otp:
      case EntityType.document:
        throw UnimplementedError();
    }
  }

  Future<_HistorySnapshot?> _loadCurrentContact(String id) async {
    final row = await store.contactDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.contact,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.phone ?? item.email ?? item.company,
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
        'phone': item.phone,
        'email': item.email,
        'company': item.company,
        'jobTitle': item.jobTitle,
        'address': item.address,
        'website': item.website,
        'birthday': item.birthday,
        'isEmergencyContact': item.isEmergencyContact,
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

  Future<List<_HistorySnapshot>> _loadContactHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.contactHistory,
              store.contactHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.contact),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.contactHistory);
      return _baseSnapshot(
        entityType: EntityType.contact,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.phone ?? item.email ?? item.company,
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
          'phone': item.phone,
          'email': item.email,
          'company': item.company,
          'jobTitle': item.jobTitle,
          'address': item.address,
          'website': item.website,
          'birthday': item.birthday,
          'isEmergencyContact': item.isEmergencyContact,
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

  Future<_HistorySnapshot?> _loadCurrentApiKey(String id) async {
    final row = await store.apiKeyDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    final secret = await store.apiKeyDao.getKeyFieldById(id);
    return _baseSnapshot(
      entityType: EntityType.apiKey,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.service,
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
        'service': item.service,
        'key': secret,
        'maskedKey': item.maskedKey,
        'tokenType': item.tokenType,
        'environment': item.environment,
        'expiresAt': item.expiresAt,
        'revoked': item.revoked,
        'rotationPeriodDays': item.rotationPeriodDays,
        'lastRotatedAt': item.lastRotatedAt,
        'metadata': item.metadata,
      },
      sensitiveKeys: const {'key'},
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

  Future<List<_HistorySnapshot>> _loadApiKeyHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.apiKeyHistory,
              store.apiKeyHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.apiKey),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.apiKeyHistory);
      return _baseSnapshot(
        entityType: EntityType.apiKey,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.service,
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
          'service': item.service,
          'key': item.key,
          'maskedKey': item.maskedKey,
          'tokenType': item.tokenType,
          'environment': item.environment,
          'expiresAt': item.expiresAt,
          'revoked': item.revoked,
          'rotationPeriodDays': item.rotationPeriodDays,
          'lastRotatedAt': item.lastRotatedAt,
          'metadata': item.metadata,
        },
        sensitiveKeys: const {'key'},
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

  Future<_HistorySnapshot?> _loadCurrentSshKey(String id) async {
    final row = await store.sshKeyDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.sshKey,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.fingerprint ?? item.keyType ?? item.usage,
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
        'publicKey': item.publicKey,
        'privateKey': item.privateKey,
        'keyType': item.keyType,
        'keySize': item.keySize,
        'passphraseHint': item.passphraseHint,
        'comment': item.comment,
        'fingerprint': item.fingerprint,
        'createdBy': item.createdBy,
        'addedToAgent': item.addedToAgent,
        'usage': item.usage,
        'publicKeyFileId': item.publicKeyFileId,
        'privateKeyFileId': item.privateKeyFileId,
        'metadata': item.metadata,
      },
      sensitiveKeys: const {'privateKey'},
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

  Future<List<_HistorySnapshot>> _loadSshKeyHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.sshKeyHistory,
              store.sshKeyHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.sshKey),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.sshKeyHistory);
      return _baseSnapshot(
        entityType: EntityType.sshKey,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.fingerprint ?? item.keyType ?? item.usage,
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
          'publicKey': item.publicKey,
          'privateKey': item.privateKey,
          'keyType': item.keyType,
          'keySize': item.keySize,
          'passphraseHint': item.passphraseHint,
          'comment': item.comment,
          'fingerprint': item.fingerprint,
          'createdBy': item.createdBy,
          'addedToAgent': item.addedToAgent,
          'usage': item.usage,
          'publicKeyFileId': item.publicKeyFileId,
          'privateKeyFileId': item.privateKeyFileId,
          'metadata': item.metadata,
        },
        sensitiveKeys: const {'privateKey'},
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

  Future<_HistorySnapshot?> _loadCurrentCertificate(String id) async {
    final row = await store.certificateDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.certificate,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.serialNumber ?? item.subject ?? item.issuer,
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
        'certificatePem': item.certificatePem,
        'privateKey': item.privateKey,
        'serialNumber': item.serialNumber,
        'issuer': item.issuer,
        'subject': item.subject,
        'validFrom': item.validFrom,
        'validTo': item.validTo,
        'fingerprint': item.fingerprint,
        'keyUsage': item.keyUsage,
        'extensions': item.extensions,
        'pfxBlob': item.pfxBlob,
        'passwordForPfx': item.passwordForPfx,
        'ocspUrl': item.ocspUrl,
        'crlUrl': item.crlUrl,
        'autoRenew': item.autoRenew,
        'lastCheckedAt': item.lastCheckedAt,
      },
      sensitiveKeys: const {'privateKey', 'pfxBlob', 'passwordForPfx'},
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

  Future<List<_HistorySnapshot>> _loadCertificateHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.certificateHistory,
              store.certificateHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(
                  VaultItemType.certificate,
                ),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.certificateHistory);
      return _baseSnapshot(
        entityType: EntityType.certificate,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.serialNumber ?? item.subject ?? item.issuer,
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
          'certificatePem': item.certificatePem,
          'privateKey': item.privateKey,
          'serialNumber': item.serialNumber,
          'issuer': item.issuer,
          'subject': item.subject,
          'validFrom': item.validFrom,
          'validTo': item.validTo,
          'fingerprint': item.fingerprint,
          'keyUsage': item.keyUsage,
          'extensions': item.extensions,
          'pfxBlob': item.pfxBlob,
          'passwordForPfx': item.passwordForPfx,
          'ocspUrl': item.ocspUrl,
          'crlUrl': item.crlUrl,
          'autoRenew': item.autoRenew,
          'lastCheckedAt': item.lastCheckedAt,
        },
        sensitiveKeys: const {'privateKey', 'pfxBlob', 'passwordForPfx'},
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

  Future<_HistorySnapshot?> _loadCurrentCryptoWallet(String id) async {
    final row = await store.cryptoWalletDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.cryptoWallet,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.network ?? item.walletType,
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
        'walletType': item.walletType,
        'mnemonic': item.mnemonic,
        'privateKey': item.privateKey,
        'derivationPath': item.derivationPath,
        'network': item.network,
        'addresses': item.addresses,
        'xpub': item.xpub,
        'xprv': item.xprv,
        'hardwareDevice': item.hardwareDevice,
        'lastBalanceCheckedAt': item.lastBalanceCheckedAt,
        'watchOnly': item.watchOnly,
        'derivationScheme': item.derivationScheme,
      },
      sensitiveKeys: const {'mnemonic', 'privateKey', 'xprv'},
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

  Future<List<_HistorySnapshot>> _loadCryptoWalletHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.cryptoWalletHistory,
              store.cryptoWalletHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(
                  VaultItemType.cryptoWallet,
                ),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.cryptoWalletHistory);
      return _baseSnapshot(
        entityType: EntityType.cryptoWallet,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.network ?? item.walletType,
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
          'walletType': item.walletType,
          'mnemonic': item.mnemonic,
          'privateKey': item.privateKey,
          'derivationPath': item.derivationPath,
          'network': item.network,
          'addresses': item.addresses,
          'xpub': item.xpub,
          'xprv': item.xprv,
          'hardwareDevice': item.hardwareDevice,
          'lastBalanceCheckedAt': item.lastBalanceCheckedAt,
          'watchOnly': item.watchOnly,
          'derivationScheme': item.derivationScheme,
        },
        sensitiveKeys: const {'mnemonic', 'privateKey', 'xprv'},
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

  Future<_HistorySnapshot?> _loadCurrentWifi(String id) async {
    final row = await store.wifiDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.wifi,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.ssid,
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
        'ssid': item.ssid,
        'password': item.password,
        'security': item.security,
        'hidden': item.hidden,
        'eapMethod': item.eapMethod,
        'username': item.username,
        'identity': item.identity,
        'domain': item.domain,
        'lastConnectedBssid': item.lastConnectedBssid,
        'priority': item.priority,
        'qrCodePayload': item.qrCodePayload,
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

  Future<List<_HistorySnapshot>> _loadWifiHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.wifiHistory,
              store.wifiHistory.historyId.equalsExp(store.vaultItemHistory.id),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.wifi),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.wifiHistory);
      return _baseSnapshot(
        entityType: EntityType.wifi,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.ssid,
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
          'ssid': item.ssid,
          'password': item.password,
          'security': item.security,
          'hidden': item.hidden,
          'eapMethod': item.eapMethod,
          'username': item.username,
          'identity': item.identity,
          'domain': item.domain,
          'lastConnectedBssid': item.lastConnectedBssid,
          'priority': item.priority,
          'qrCodePayload': item.qrCodePayload,
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

  Future<_HistorySnapshot?> _loadCurrentIdentity(String id) async {
    final row = await store.identityDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.identity,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.fullName ?? item.idNumber,
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
        'idType': item.idType,
        'idNumber': item.idNumber,
        'fullName': item.fullName,
        'dateOfBirth': item.dateOfBirth,
        'placeOfBirth': item.placeOfBirth,
        'nationality': item.nationality,
        'issuingAuthority': item.issuingAuthority,
        'issueDate': item.issueDate,
        'expiryDate': item.expiryDate,
        'mrz': item.mrz,
        'scanAttachmentId': item.scanAttachmentId,
        'photoAttachmentId': item.photoAttachmentId,
        'verified': item.verified,
      },
      sensitiveKeys: const {'idNumber', 'mrz'},
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

  Future<List<_HistorySnapshot>> _loadIdentityHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.identityHistory,
              store.identityHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(VaultItemType.identity),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.identityHistory);
      return _baseSnapshot(
        entityType: EntityType.identity,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.fullName ?? item.idNumber,
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
          'idType': item.idType,
          'idNumber': item.idNumber,
          'fullName': item.fullName,
          'dateOfBirth': item.dateOfBirth,
          'placeOfBirth': item.placeOfBirth,
          'nationality': item.nationality,
          'issuingAuthority': item.issuingAuthority,
          'issueDate': item.issueDate,
          'expiryDate': item.expiryDate,
          'mrz': item.mrz,
          'scanAttachmentId': item.scanAttachmentId,
          'photoAttachmentId': item.photoAttachmentId,
          'verified': item.verified,
        },
        sensitiveKeys: const {'idNumber', 'mrz'},
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

  Future<_HistorySnapshot?> _loadCurrentLicenseKey(String id) async {
    final row = await store.licenseKeyDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.licenseKey,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.product,
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
        'product': item.product,
        'licenseKey': item.licenseKey,
        'licenseType': item.licenseType,
        'seats': item.seats,
        'maxActivations': item.maxActivations,
        'activatedOn': item.activatedOn,
        'purchaseDate': item.purchaseDate,
        'purchaseFrom': item.purchaseFrom,
        'orderId': item.orderId,
        'licenseFileId': item.licenseFileId,
        'expiresAt': item.expiresAt,
        'supportContact': item.supportContact,
      },
      sensitiveKeys: const {'licenseKey'},
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

  Future<List<_HistorySnapshot>> _loadLicenseKeyHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.licenseKeyHistory,
              store.licenseKeyHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(
                  VaultItemType.licenseKey,
                ),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.licenseKeyHistory);
      return _baseSnapshot(
        entityType: EntityType.licenseKey,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.product,
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
          'product': item.product,
          'licenseKey': item.licenseKey,
          'licenseType': item.licenseType,
          'seats': item.seats,
          'maxActivations': item.maxActivations,
          'activatedOn': item.activatedOn,
          'purchaseDate': item.purchaseDate,
          'purchaseFrom': item.purchaseFrom,
          'orderId': item.orderId,
          'licenseFileId': item.licenseFileId,
          'expiresAt': item.expiresAt,
          'supportContact': item.supportContact,
        },
        sensitiveKeys: const {'licenseKey'},
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

  Future<_HistorySnapshot?> _loadCurrentRecoveryCodes(String id) async {
    final row = await store.recoveryCodesDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final codes = await store.recoveryCodesDao.getCodesForItem(id);
    final vault = row.$1;
    final item = row.$2;
    final codesCount = codes.length;
    final usedCountCodes = codes.where((code) => code.used).length;
    return _baseSnapshot(
      entityType: EntityType.recoveryCodes,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.displayHint,
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
        'codesCount': codesCount,
        'usedCountCodes': usedCountCodes,
        'oneTime': item.oneTime,
        'displayHint': item.displayHint,
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
        t.history.recovery_codes_restore_unavailable,
      ],
      isRestorable: false,
    );
  }

  Future<List<_HistorySnapshot>> _loadRecoveryCodesHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.recoveryCodesHistory,
              store.recoveryCodesHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(
                  VaultItemType.recoveryCodes,
                ),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.recoveryCodesHistory);
      return _baseSnapshot(
        entityType: EntityType.recoveryCodes,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.displayHint,
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
          'codesCount': item.codesCount,
          'usedCountCodes': item.usedCount,
          'oneTime': item.oneTime,
          'displayHint': item.displayHint,
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
          t.history.recovery_codes_restore_unavailable,
        ],
        isRestorable: false,
      );
    }).toList();
  }

  Future<_HistorySnapshot?> _loadCurrentLoyaltyCard(String id) async {
    final row = await store.loyaltyCardDao.getById(id);
    if (row == null) return null;
    final customFields = await _loadLiveCustomFields(id);
    final vault = row.$1;
    final item = row.$2;
    return _baseSnapshot(
      entityType: EntityType.loyaltyCard,
      revisionId: '__live__$id',
      originalEntityId: id,
      action: 'live',
      actionAt: vault.modifiedAt,
      title: vault.name,
      subtitle: item.programName,
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
        'programName': item.programName,
        'cardNumber': item.cardNumber,
        'holderName': item.holderName,
        'barcodeValue': item.barcodeValue,
        'barcodeType': item.barcodeType,
        'password': item.password,
        'pointsBalance': item.pointsBalance,
        'tier': item.tier,
        'expiryDate': item.expiryDate,
        'website': item.website,
        'phoneNumber': item.phoneNumber,
      },
      sensitiveKeys: const {'password', 'cardNumber', 'barcodeValue'},
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

  Future<List<_HistorySnapshot>> _loadLoyaltyCardHistory(String id) async {
    final query =
        store.select(store.vaultItemHistory).join([
            innerJoin(
              store.loyaltyCardHistory,
              store.loyaltyCardHistory.historyId.equalsExp(
                store.vaultItemHistory.id,
              ),
            ),
          ])
          ..where(
            store.vaultItemHistory.itemId.equals(id) &
                store.vaultItemHistory.type.equalsValue(
                  VaultItemType.loyaltyCard,
                ),
          )
          ..orderBy([OrderingTerm.desc(store.vaultItemHistory.actionAt)]);
    final rows = await query.get();
    final historyFields = await _loadHistoryCustomFields(
      rows.map((row) => row.readTable(store.vaultItemHistory).id),
    );
    return rows.map((row) {
      final vault = row.readTable(store.vaultItemHistory);
      final item = row.readTable(store.loyaltyCardHistory);
      return _baseSnapshot(
        entityType: EntityType.loyaltyCard,
        revisionId: vault.id,
        originalEntityId: vault.itemId,
        action: vault.action.value,
        actionAt: vault.actionAt,
        title: vault.name,
        subtitle: item.programName,
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
          'programName': item.programName,
          'cardNumber': item.cardNumber,
          'holderName': item.holderName,
          'barcodeValue': item.barcodeValue,
          'barcodeType': item.barcodeType,
          'password': item.password,
          'pointsBalance': item.pointsBalance,
          'tier': item.tier,
          'expiryDate': item.expiryDate,
          'website': item.website,
          'phoneNumber': item.phoneNumber,
        },
        sensitiveKeys: const {'password', 'cardNumber', 'barcodeValue'},
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
