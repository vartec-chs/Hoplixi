part of 'history_repository.dart';

extension _HistoryRepositoryRestore on HistoryRepository {
  String _requiredString(
    Map<String, Object?> fields,
    String key, [
    String fallback = '',
  ]) => (fields[key] as String?) ?? fallback;

  String _requiredNumberString(
    Map<String, Object?> fields,
    String key, {
    required int fallback,
    int? padLeft,
  }) {
    final value = fields[key];
    final stringValue = switch (value) {
      int number => number.toString(),
      String text when text.isNotEmpty => text,
      _ => fallback.toString(),
    };
    return padLeft == null ? stringValue : stringValue.padLeft(padLeft, '0');
  }

  Future<void> _upsertVaultItem(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    if (recreate) {
      await store
          .into(store.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(snapshot.originalEntityId),
              type: _toVaultType(snapshot.entityType),
              name: snapshot.title,
              description: Value(snapshot.description),
              categoryId: Value(snapshot.categoryId),
              usedCount: Value(snapshot.usedCount),
              isFavorite: Value(snapshot.isFavorite),
              isArchived: Value(snapshot.isArchived),
              isPinned: Value(snapshot.isPinned),
              isDeleted: const Value(false),
              createdAt: Value(snapshot.originalCreatedAt ?? snapshot.actionAt),
              modifiedAt: Value(DateTime.now()),
              recentScore: Value(snapshot.recentScore),
              lastUsedAt: Value(snapshot.lastUsedAt),
            ),
          );
      return;
    }

    await (store.update(
      store.vaultItems,
    )..where((tbl) => tbl.id.equals(snapshot.originalEntityId))).write(
      VaultItemsCompanion(
        name: Value(snapshot.title),
        description: Value(snapshot.description),
        categoryId: Value(snapshot.categoryId),
        usedCount: Value(snapshot.usedCount),
        isFavorite: Value(snapshot.isFavorite),
        isArchived: Value(snapshot.isArchived),
        isPinned: Value(snapshot.isPinned),
        isDeleted: const Value(false),
        recentScore: Value(snapshot.recentScore),
        lastUsedAt: Value(snapshot.lastUsedAt),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _upsertTypeSpecific(
    EntityType entityType,
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) {
    switch (entityType) {
      case EntityType.password:
        return _restorePassword(snapshot, recreate: recreate);
      case EntityType.note:
        return _restoreNote(snapshot, recreate: recreate);
      case EntityType.bankCard:
        return _restoreBankCard(snapshot, recreate: recreate);
      case EntityType.file:
        return _restoreFile(snapshot, recreate: recreate);
      case EntityType.otp:
        return _restoreOtp(snapshot, recreate: recreate);
      case EntityType.document:
        return _restoreDocument(snapshot, recreate: recreate);
      case EntityType.contact:
        return _restoreContact(snapshot, recreate: recreate);
      case EntityType.apiKey:
        return _restoreApiKey(snapshot, recreate: recreate);
      case EntityType.sshKey:
        return _restoreSshKey(snapshot, recreate: recreate);
      case EntityType.certificate:
        return _restoreCertificate(snapshot, recreate: recreate);
      case EntityType.cryptoWallet:
        return _restoreCryptoWallet(snapshot, recreate: recreate);
      case EntityType.wifi:
        return _restoreWifi(snapshot, recreate: recreate);
      case EntityType.identity:
        return _restoreIdentity(snapshot, recreate: recreate);
      case EntityType.licenseKey:
        return _restoreLicenseKey(snapshot, recreate: recreate);
      case EntityType.recoveryCodes:
        throw StateError(t.history.recovery_codes_restore_unavailable);
      case EntityType.loyaltyCard:
        return _restoreLoyaltyCard(snapshot, recreate: recreate);
    }
  }

  Future<void> _restorePassword(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = PasswordItemsCompanion(
      password: Value(_requiredString(snapshot.fields, 'password')),
      login: Value(snapshot.fields['login'] as String?),
      email: Value(snapshot.fields['email'] as String?),
      url: Value(snapshot.fields['url'] as String?),
      expireAt: Value(snapshot.fields['expireAt'] as DateTime?),
    );
    if (recreate) {
      await store
          .into(store.passwordItems)
          .insert(
            PasswordItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              password: _requiredString(snapshot.fields, 'password'),
              login: Value(snapshot.fields['login'] as String?),
              email: Value(snapshot.fields['email'] as String?),
              url: Value(snapshot.fields['url'] as String?),
              expireAt: Value(snapshot.fields['expireAt'] as DateTime?),
            ),
          );
      return;
    }
    await (store.update(store.passwordItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreNote(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final deltaJson = snapshot.fields['deltaJson'] as String? ?? '[]';
    if (recreate) {
      await store
          .into(store.noteItems)
          .insert(
            NoteItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              deltaJson: deltaJson,
              content: _requiredString(snapshot.fields, 'content'),
            ),
          );
      return;
    }
    await (store.update(
      store.noteItems,
    )..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId))).write(
      NoteItemsCompanion(
        deltaJson: Value(deltaJson),
        content: Value(_requiredString(snapshot.fields, 'content')),
      ),
    );
  }

  Future<void> _restoreBankCard(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final cardType = snapshot.fields['cardType'] as String?;
    final cardNetwork = snapshot.fields['cardNetwork'] as String?;
    final companion = BankCardItemsCompanion(
      cardholderName: Value(_requiredString(snapshot.fields, 'cardholderName')),
      cardNumber: Value(_requiredString(snapshot.fields, 'cardNumber')),
      expiryMonth: Value(
        _requiredNumberString(
          snapshot.fields,
          'expiryMonth',
          fallback: 1,
          padLeft: 2,
        ),
      ),
      expiryYear: Value(
        _requiredNumberString(
          snapshot.fields,
          'expiryYear',
          fallback: 1970,
          padLeft: 4,
        ),
      ),
      cardType: cardType == null
          ? const Value.absent()
          : Value(CardTypeX.fromString(cardType)),
      cardNetwork: cardNetwork == null
          ? const Value.absent()
          : Value(CardNetworkX.fromString(cardNetwork)),
      cvv: Value(snapshot.fields['cvv'] as String?),
      bankName: Value(snapshot.fields['bankName'] as String?),
      accountNumber: Value(snapshot.fields['accountNumber'] as String?),
      routingNumber: Value(snapshot.fields['routingNumber'] as String?),
    );
    if (recreate) {
      await store
          .into(store.bankCardItems)
          .insert(
            BankCardItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              cardholderName: _requiredString(
                snapshot.fields,
                'cardholderName',
              ),
              cardNumber: _requiredString(snapshot.fields, 'cardNumber'),
              expiryMonth: _requiredNumberString(
                snapshot.fields,
                'expiryMonth',
                fallback: 1,
                padLeft: 2,
              ),
              expiryYear: _requiredNumberString(
                snapshot.fields,
                'expiryYear',
                fallback: 1970,
                padLeft: 4,
              ),
              cardType: cardType == null
                  ? const Value.absent()
                  : Value(CardTypeX.fromString(cardType)),
              cardNetwork: cardNetwork == null
                  ? const Value.absent()
                  : Value(CardNetworkX.fromString(cardNetwork)),
              cvv: Value(snapshot.fields['cvv'] as String?),
              bankName: Value(snapshot.fields['bankName'] as String?),
              accountNumber: Value(snapshot.fields['accountNumber'] as String?),
              routingNumber: Value(snapshot.fields['routingNumber'] as String?),
            ),
          );
      return;
    }
    await (store.update(store.bankCardItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreFile(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final metadataId = snapshot.fields['metadataId'] as String?;
    if (metadataId == null) throw StateError('File metadata is missing.');
    final metadata = await store.fileDao.getFileMetadataById(metadataId);
    if (metadata == null ||
        metadata.filePath == null ||
        !await File(metadata.filePath!).exists()) {
      throw StateError('Historical file content is no longer available.');
    }
    if (recreate) {
      await store
          .into(store.fileItems)
          .insert(
            FileItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              metadataId: Value(metadataId),
            ),
          );
      return;
    }
    await (store.update(store.fileItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(FileItemsCompanion(metadataId: Value(metadataId)));
  }

  Future<void> _restoreOtp(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final secret = snapshot.fields['secret'];
    final bytes = switch (secret) {
      Uint8List value => value,
      List<int> value => Uint8List.fromList(value),
      _ => Uint8List(0),
    };
    final type = OtpTypeX.fromString(
      (snapshot.fields['otpType'] as String?) ?? OtpType.totp.value,
    );
    final encoding = SecretEncodingX.fromString(
      (snapshot.fields['secretEncoding'] as String?) ??
          SecretEncoding.BASE32.value,
    );
    final algorithm = AlgorithmOtpX.fromString(
      (snapshot.fields['algorithm'] as String?) ?? AlgorithmOtp.SHA1.value,
    );
    if (recreate) {
      await store
          .into(store.otpItems)
          .insert(
            OtpItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              type: Value(type),
              secret: bytes,
              secretEncoding: Value(encoding),
              issuer: Value(snapshot.fields['issuer'] as String?),
              accountName: Value(snapshot.fields['accountName'] as String?),
              algorithm: Value(algorithm),
              digits: Value(snapshot.fields['digits'] as int? ?? 6),
              period: Value(snapshot.fields['period'] as int? ?? 30),
              counter: Value(snapshot.fields['counter'] as int?),
              passwordItemId: Value(
                snapshot.fields['passwordItemId'] as String?,
              ),
            ),
          );
      return;
    }
    await (store.update(
      store.otpItems,
    )..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId))).write(
      OtpItemsCompanion(
        type: Value(type),
        secret: Value(bytes),
        secretEncoding: Value(encoding),
        issuer: Value(snapshot.fields['issuer'] as String?),
        accountName: Value(snapshot.fields['accountName'] as String?),
        algorithm: Value(algorithm),
        digits: Value(snapshot.fields['digits'] as int? ?? 6),
        period: Value(snapshot.fields['period'] as int? ?? 30),
        counter: Value(snapshot.fields['counter'] as int?),
        passwordItemId: Value(snapshot.fields['passwordItemId'] as String?),
      ),
    );
  }

  Future<void> _restoreDocument(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = DocumentItemsCompanion(
      documentType: Value(snapshot.fields['documentType'] as String?),
      aggregatedText: Value(snapshot.fields['aggregatedText'] as String?),
      pageCount: Value(snapshot.fields['pageCount'] as int? ?? 0),
    );
    if (recreate) {
      await store
          .into(store.documentItems)
          .insert(
            DocumentItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              documentType: Value(snapshot.fields['documentType'] as String?),
              aggregatedText: Value(
                snapshot.fields['aggregatedText'] as String?,
              ),
              aggregateHash: const Value.absent(),
              pageCount: Value(snapshot.fields['pageCount'] as int? ?? 0),
            ),
          );
      return;
    }
    await (store.update(store.documentItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreContact(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = ContactItemsCompanion(
      phone: Value(snapshot.fields['phone'] as String?),
      email: Value(snapshot.fields['email'] as String?),
      company: Value(snapshot.fields['company'] as String?),
      jobTitle: Value(snapshot.fields['jobTitle'] as String?),
      address: Value(snapshot.fields['address'] as String?),
      website: Value(snapshot.fields['website'] as String?),
      birthday: Value(snapshot.fields['birthday'] as DateTime?),
      isEmergencyContact: Value(
        snapshot.fields['isEmergencyContact'] as bool? ?? false,
      ),
    );
    if (recreate) {
      await store
          .into(store.contactItems)
          .insert(
            ContactItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              phone: Value(snapshot.fields['phone'] as String?),
              email: Value(snapshot.fields['email'] as String?),
              company: Value(snapshot.fields['company'] as String?),
              jobTitle: Value(snapshot.fields['jobTitle'] as String?),
              address: Value(snapshot.fields['address'] as String?),
              website: Value(snapshot.fields['website'] as String?),
              birthday: Value(snapshot.fields['birthday'] as DateTime?),
              isEmergencyContact: Value(
                snapshot.fields['isEmergencyContact'] as bool? ?? false,
              ),
            ),
          );
      return;
    }
    await (store.update(store.contactItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreApiKey(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = ApiKeyItemsCompanion(
      service: Value(_requiredString(snapshot.fields, 'service')),
      key: Value(_requiredString(snapshot.fields, 'key')),
      maskedKey: Value(snapshot.fields['maskedKey'] as String?),
      tokenType: Value(snapshot.fields['tokenType'] as String?),
      environment: Value(snapshot.fields['environment'] as String?),
      expiresAt: Value(snapshot.fields['expiresAt'] as DateTime?),
      revoked: Value(snapshot.fields['revoked'] as bool? ?? false),
      rotationPeriodDays: Value(snapshot.fields['rotationPeriodDays'] as int?),
      lastRotatedAt: Value(snapshot.fields['lastRotatedAt'] as DateTime?),
      metadata: Value(snapshot.fields['metadata'] as String?),
    );
    if (recreate) {
      await store
          .into(store.apiKeyItems)
          .insert(
            ApiKeyItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              service: _requiredString(snapshot.fields, 'service'),
              key: _requiredString(snapshot.fields, 'key'),
              maskedKey: Value(snapshot.fields['maskedKey'] as String?),
              tokenType: Value(snapshot.fields['tokenType'] as String?),
              environment: Value(snapshot.fields['environment'] as String?),
              expiresAt: Value(snapshot.fields['expiresAt'] as DateTime?),
              revoked: Value(snapshot.fields['revoked'] as bool? ?? false),
              rotationPeriodDays: Value(
                snapshot.fields['rotationPeriodDays'] as int?,
              ),
              lastRotatedAt: Value(
                snapshot.fields['lastRotatedAt'] as DateTime?,
              ),
              metadata: Value(snapshot.fields['metadata'] as String?),
            ),
          );
      return;
    }
    await (store.update(store.apiKeyItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreSshKey(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = SshKeyItemsCompanion(
      publicKey: Value(_requiredString(snapshot.fields, 'publicKey')),
      privateKey: Value(_requiredString(snapshot.fields, 'privateKey')),
      keyType: Value(snapshot.fields['keyType'] as String?),
      keySize: Value(snapshot.fields['keySize'] as int?),
      passphraseHint: Value(snapshot.fields['passphraseHint'] as String?),
      comment: Value(snapshot.fields['comment'] as String?),
      fingerprint: Value(snapshot.fields['fingerprint'] as String?),
      createdBy: Value(snapshot.fields['createdBy'] as String?),
      addedToAgent: Value(snapshot.fields['addedToAgent'] as bool? ?? false),
      usage: Value(snapshot.fields['usage'] as String?),
      publicKeyFileId: Value(snapshot.fields['publicKeyFileId'] as String?),
      privateKeyFileId: Value(snapshot.fields['privateKeyFileId'] as String?),
      metadata: Value(snapshot.fields['metadata'] as String?),
    );
    if (recreate) {
      await store
          .into(store.sshKeyItems)
          .insert(
            SshKeyItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              publicKey: _requiredString(snapshot.fields, 'publicKey'),
              privateKey: _requiredString(snapshot.fields, 'privateKey'),
              keyType: Value(snapshot.fields['keyType'] as String?),
              keySize: Value(snapshot.fields['keySize'] as int?),
              passphraseHint: Value(
                snapshot.fields['passphraseHint'] as String?,
              ),
              comment: Value(snapshot.fields['comment'] as String?),
              fingerprint: Value(snapshot.fields['fingerprint'] as String?),
              createdBy: Value(snapshot.fields['createdBy'] as String?),
              addedToAgent: Value(
                snapshot.fields['addedToAgent'] as bool? ?? false,
              ),
              usage: Value(snapshot.fields['usage'] as String?),
              publicKeyFileId: Value(
                snapshot.fields['publicKeyFileId'] as String?,
              ),
              privateKeyFileId: Value(
                snapshot.fields['privateKeyFileId'] as String?,
              ),
              metadata: Value(snapshot.fields['metadata'] as String?),
            ),
          );
      return;
    }
    await (store.update(store.sshKeyItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreCertificate(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final pfxBlob = switch (snapshot.fields['pfxBlob']) {
      Uint8List value => value,
      List<int> value => Uint8List.fromList(value),
      _ => null,
    };
    final companion = CertificateItemsCompanion(
      certificatePem: Value(_requiredString(snapshot.fields, 'certificatePem')),
      privateKey: Value(snapshot.fields['privateKey'] as String?),
      serialNumber: Value(snapshot.fields['serialNumber'] as String?),
      issuer: Value(snapshot.fields['issuer'] as String?),
      subject: Value(snapshot.fields['subject'] as String?),
      validFrom: Value(snapshot.fields['validFrom'] as DateTime?),
      validTo: Value(snapshot.fields['validTo'] as DateTime?),
      fingerprint: Value(snapshot.fields['fingerprint'] as String?),
      keyUsage: Value(snapshot.fields['keyUsage'] as String?),
      extensions: Value(snapshot.fields['extensions'] as String?),
      pfxBlob: Value(pfxBlob),
      passwordForPfx: Value(snapshot.fields['passwordForPfx'] as String?),
      ocspUrl: Value(snapshot.fields['ocspUrl'] as String?),
      crlUrl: Value(snapshot.fields['crlUrl'] as String?),
      autoRenew: Value(snapshot.fields['autoRenew'] as bool? ?? false),
      lastCheckedAt: Value(snapshot.fields['lastCheckedAt'] as DateTime?),
    );
    if (recreate) {
      await store
          .into(store.certificateItems)
          .insert(
            CertificateItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              certificatePem: _requiredString(
                snapshot.fields,
                'certificatePem',
              ),
              privateKey: Value(snapshot.fields['privateKey'] as String?),
              serialNumber: Value(snapshot.fields['serialNumber'] as String?),
              issuer: Value(snapshot.fields['issuer'] as String?),
              subject: Value(snapshot.fields['subject'] as String?),
              validFrom: Value(snapshot.fields['validFrom'] as DateTime?),
              validTo: Value(snapshot.fields['validTo'] as DateTime?),
              fingerprint: Value(snapshot.fields['fingerprint'] as String?),
              keyUsage: Value(snapshot.fields['keyUsage'] as String?),
              extensions: Value(snapshot.fields['extensions'] as String?),
              pfxBlob: Value(pfxBlob),
              passwordForPfx: Value(
                snapshot.fields['passwordForPfx'] as String?,
              ),
              ocspUrl: Value(snapshot.fields['ocspUrl'] as String?),
              crlUrl: Value(snapshot.fields['crlUrl'] as String?),
              autoRenew: Value(snapshot.fields['autoRenew'] as bool? ?? false),
              lastCheckedAt: Value(
                snapshot.fields['lastCheckedAt'] as DateTime?,
              ),
            ),
          );
      return;
    }
    await (store.update(store.certificateItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreCryptoWallet(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = CryptoWalletItemsCompanion(
      walletType: Value(_requiredString(snapshot.fields, 'walletType')),
      mnemonic: Value(snapshot.fields['mnemonic'] as String?),
      privateKey: Value(snapshot.fields['privateKey'] as String?),
      derivationPath: Value(snapshot.fields['derivationPath'] as String?),
      network: Value(snapshot.fields['network'] as String?),
      addresses: Value(snapshot.fields['addresses'] as String?),
      xpub: Value(snapshot.fields['xpub'] as String?),
      xprv: Value(snapshot.fields['xprv'] as String?),
      hardwareDevice: Value(snapshot.fields['hardwareDevice'] as String?),
      lastBalanceCheckedAt: Value(
        snapshot.fields['lastBalanceCheckedAt'] as DateTime?,
      ),
      watchOnly: Value(snapshot.fields['watchOnly'] as bool? ?? false),
      derivationScheme: Value(snapshot.fields['derivationScheme'] as String?),
    );
    if (recreate) {
      await store
          .into(store.cryptoWalletItems)
          .insert(
            CryptoWalletItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              walletType: _requiredString(snapshot.fields, 'walletType'),
              mnemonic: Value(snapshot.fields['mnemonic'] as String?),
              privateKey: Value(snapshot.fields['privateKey'] as String?),
              derivationPath: Value(
                snapshot.fields['derivationPath'] as String?,
              ),
              network: Value(snapshot.fields['network'] as String?),
              addresses: Value(snapshot.fields['addresses'] as String?),
              xpub: Value(snapshot.fields['xpub'] as String?),
              xprv: Value(snapshot.fields['xprv'] as String?),
              hardwareDevice: Value(
                snapshot.fields['hardwareDevice'] as String?,
              ),
              lastBalanceCheckedAt: Value(
                snapshot.fields['lastBalanceCheckedAt'] as DateTime?,
              ),
              watchOnly: Value(snapshot.fields['watchOnly'] as bool? ?? false),
              derivationScheme: Value(
                snapshot.fields['derivationScheme'] as String?,
              ),
            ),
          );
      return;
    }
    await (store.update(store.cryptoWalletItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreWifi(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = WifiItemsCompanion(
      ssid: Value(_requiredString(snapshot.fields, 'ssid')),
      password: Value(snapshot.fields['password'] as String?),
      security: Value(snapshot.fields['security'] as String?),
      hidden: Value(snapshot.fields['hidden'] as bool? ?? false),
      eapMethod: Value(snapshot.fields['eapMethod'] as String?),
      username: Value(snapshot.fields['username'] as String?),
      identity: Value(snapshot.fields['identity'] as String?),
      domain: Value(snapshot.fields['domain'] as String?),
      lastConnectedBssid: Value(
        snapshot.fields['lastConnectedBssid'] as String?,
      ),
      priority: Value(snapshot.fields['priority'] as int?),
      qrCodePayload: Value(snapshot.fields['qrCodePayload'] as String?),
    );
    if (recreate) {
      await store
          .into(store.wifiItems)
          .insert(
            WifiItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              ssid: _requiredString(snapshot.fields, 'ssid'),
              password: Value(snapshot.fields['password'] as String?),
              security: Value(snapshot.fields['security'] as String?),
              hidden: Value(snapshot.fields['hidden'] as bool? ?? false),
              eapMethod: Value(snapshot.fields['eapMethod'] as String?),
              username: Value(snapshot.fields['username'] as String?),
              identity: Value(snapshot.fields['identity'] as String?),
              domain: Value(snapshot.fields['domain'] as String?),
              lastConnectedBssid: Value(
                snapshot.fields['lastConnectedBssid'] as String?,
              ),
              priority: Value(snapshot.fields['priority'] as int?),
              qrCodePayload: Value(snapshot.fields['qrCodePayload'] as String?),
            ),
          );
      return;
    }
    await (store.update(store.wifiItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreIdentity(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = IdentityItemsCompanion(
      idType: Value(_requiredString(snapshot.fields, 'idType')),
      idNumber: Value(_requiredString(snapshot.fields, 'idNumber')),
      fullName: Value(snapshot.fields['fullName'] as String?),
      dateOfBirth: Value(snapshot.fields['dateOfBirth'] as DateTime?),
      placeOfBirth: Value(snapshot.fields['placeOfBirth'] as String?),
      nationality: Value(snapshot.fields['nationality'] as String?),
      issuingAuthority: Value(snapshot.fields['issuingAuthority'] as String?),
      issueDate: Value(snapshot.fields['issueDate'] as DateTime?),
      expiryDate: Value(snapshot.fields['expiryDate'] as DateTime?),
      mrz: Value(snapshot.fields['mrz'] as String?),
      scanAttachmentId: Value(snapshot.fields['scanAttachmentId'] as String?),
      photoAttachmentId: Value(snapshot.fields['photoAttachmentId'] as String?),
      verified: Value(snapshot.fields['verified'] as bool? ?? false),
    );
    if (recreate) {
      await store
          .into(store.identityItems)
          .insert(
            IdentityItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              idType: _requiredString(snapshot.fields, 'idType'),
              idNumber: _requiredString(snapshot.fields, 'idNumber'),
              fullName: Value(snapshot.fields['fullName'] as String?),
              dateOfBirth: Value(snapshot.fields['dateOfBirth'] as DateTime?),
              placeOfBirth: Value(snapshot.fields['placeOfBirth'] as String?),
              nationality: Value(snapshot.fields['nationality'] as String?),
              issuingAuthority: Value(
                snapshot.fields['issuingAuthority'] as String?,
              ),
              issueDate: Value(snapshot.fields['issueDate'] as DateTime?),
              expiryDate: Value(snapshot.fields['expiryDate'] as DateTime?),
              mrz: Value(snapshot.fields['mrz'] as String?),
              scanAttachmentId: Value(
                snapshot.fields['scanAttachmentId'] as String?,
              ),
              photoAttachmentId: Value(
                snapshot.fields['photoAttachmentId'] as String?,
              ),
              verified: Value(snapshot.fields['verified'] as bool? ?? false),
            ),
          );
      return;
    }
    await (store.update(store.identityItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreLicenseKey(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = LicenseKeyItemsCompanion(
      product: Value(_requiredString(snapshot.fields, 'product')),
      licenseKey: Value(_requiredString(snapshot.fields, 'licenseKey')),
      licenseType: Value(snapshot.fields['licenseType'] as String?),
      seats: Value(snapshot.fields['seats'] as int?),
      maxActivations: Value(snapshot.fields['maxActivations'] as int?),
      activatedOn: Value(snapshot.fields['activatedOn'] as DateTime?),
      purchaseDate: Value(snapshot.fields['purchaseDate'] as DateTime?),
      purchaseFrom: Value(snapshot.fields['purchaseFrom'] as String?),
      orderId: Value(snapshot.fields['orderId'] as String?),
      licenseFileId: Value(snapshot.fields['licenseFileId'] as String?),
      expiresAt: Value(snapshot.fields['expiresAt'] as DateTime?),
      supportContact: Value(snapshot.fields['supportContact'] as String?),
    );
    if (recreate) {
      await store
          .into(store.licenseKeyItems)
          .insert(
            LicenseKeyItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              product: _requiredString(snapshot.fields, 'product'),
              licenseKey: _requiredString(snapshot.fields, 'licenseKey'),
              licenseType: Value(snapshot.fields['licenseType'] as String?),
              seats: Value(snapshot.fields['seats'] as int?),
              maxActivations: Value(snapshot.fields['maxActivations'] as int?),
              activatedOn: Value(snapshot.fields['activatedOn'] as DateTime?),
              purchaseDate: Value(snapshot.fields['purchaseDate'] as DateTime?),
              purchaseFrom: Value(snapshot.fields['purchaseFrom'] as String?),
              orderId: Value(snapshot.fields['orderId'] as String?),
              licenseFileId: Value(snapshot.fields['licenseFileId'] as String?),
              expiresAt: Value(snapshot.fields['expiresAt'] as DateTime?),
              supportContact: Value(
                snapshot.fields['supportContact'] as String?,
              ),
            ),
          );
      return;
    }
    await (store.update(store.licenseKeyItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  Future<void> _restoreLoyaltyCard(
    _HistorySnapshot snapshot, {
    required bool recreate,
  }) async {
    final companion = LoyaltyCardItemsCompanion(
      programName: Value(_requiredString(snapshot.fields, 'programName')),
      cardNumber: Value(snapshot.fields['cardNumber'] as String?),
      holderName: Value(snapshot.fields['holderName'] as String?),
      barcodeValue: Value(snapshot.fields['barcodeValue'] as String?),
      barcodeType: Value(snapshot.fields['barcodeType'] as String?),
      password: Value(snapshot.fields['password'] as String?),
      pointsBalance: Value(snapshot.fields['pointsBalance'] as String?),
      tier: Value(snapshot.fields['tier'] as String?),
      expiryDate: Value(snapshot.fields['expiryDate'] as DateTime?),
      website: Value(snapshot.fields['website'] as String?),
      phoneNumber: Value(snapshot.fields['phoneNumber'] as String?),
    );
    if (recreate) {
      await store
          .into(store.loyaltyCardItems)
          .insert(
            LoyaltyCardItemsCompanion.insert(
              itemId: snapshot.originalEntityId,
              programName: _requiredString(snapshot.fields, 'programName'),
              cardNumber: Value(snapshot.fields['cardNumber'] as String?),
              holderName: Value(snapshot.fields['holderName'] as String?),
              barcodeValue: Value(snapshot.fields['barcodeValue'] as String?),
              barcodeType: Value(snapshot.fields['barcodeType'] as String?),
              password: Value(snapshot.fields['password'] as String?),
              pointsBalance: Value(snapshot.fields['pointsBalance'] as String?),
              tier: Value(snapshot.fields['tier'] as String?),
              expiryDate: Value(snapshot.fields['expiryDate'] as DateTime?),
              website: Value(snapshot.fields['website'] as String?),
              phoneNumber: Value(snapshot.fields['phoneNumber'] as String?),
            ),
          );
      return;
    }
    await (store.update(store.loyaltyCardItems)
          ..where((tbl) => tbl.itemId.equals(snapshot.originalEntityId)))
        .write(companion);
  }

  VaultItemType _toVaultType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return VaultItemType.password;
      case EntityType.note:
        return VaultItemType.note;
      case EntityType.bankCard:
        return VaultItemType.bankCard;
      case EntityType.file:
        return VaultItemType.file;
      case EntityType.otp:
        return VaultItemType.otp;
      case EntityType.document:
        return VaultItemType.document;
      case EntityType.contact:
        return VaultItemType.contact;
      case EntityType.apiKey:
        return VaultItemType.apiKey;
      case EntityType.sshKey:
        return VaultItemType.sshKey;
      case EntityType.certificate:
        return VaultItemType.certificate;
      case EntityType.cryptoWallet:
        return VaultItemType.cryptoWallet;
      case EntityType.wifi:
        return VaultItemType.wifi;
      case EntityType.identity:
        return VaultItemType.identity;
      case EntityType.licenseKey:
        return VaultItemType.licenseKey;
      case EntityType.recoveryCodes:
        return VaultItemType.recoveryCodes;
      case EntityType.loyaltyCard:
        return VaultItemType.loyaltyCard;
    }
  }
}
