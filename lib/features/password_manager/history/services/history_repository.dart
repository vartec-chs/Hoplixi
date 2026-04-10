import 'dart:io';

import 'package:drift/drift.dart';

import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/models/dto/custom_field_dto.dart';
import 'package:hoplixi/db_core/models/enums/index.dart';

part 'history_repository_loaders_primary.dart';
part 'history_repository_loaders_secondary.dart';
part 'history_repository_restore.dart';

class HistoryRepository {
  const HistoryRepository(this.store);

  final MainStore store;

  Future<_HistoryLoadResult> loadHistory(HistoryQueryState query) async {
    final history = await _loadSnapshots(query.entityType, query.entityId);
    final current = await _loadCurrentSnapshot(
      query.entityType,
      query.entityId,
    );
    final filtered = _applyFilters(history, query);
    final paged = filtered.take(query.page * query.pageSize).toList();
    final timelineItems = paged.map((snapshot) {
      final detail = _buildDetail(
        entityType: query.entityType,
        selected: snapshot,
        history: history,
        current: current,
      );
      return HistoryTimelineItem(
        revisionId: snapshot.revisionId,
        originalEntityId: snapshot.originalEntityId,
        action: snapshot.action,
        title: snapshot.title,
        subtitle: snapshot.subtitle,
        actionAt: snapshot.actionAt,
        changedFieldsCount:
            detail.fieldDiffs.length + detail.customFieldDiffs.length,
        changedFieldLabels: [
          ...detail.fieldDiffs.map((diff) => diff.label),
          ...detail.customFieldDiffs.map((diff) => diff.label),
        ].take(3).toList(),
        isRestorable: detail.isRestorable,
        restoreWarnings: detail.restoreWarnings,
      );
    }).toList();

    return _HistoryLoadResult(
      history: history,
      current: current,
      timelineItems: timelineItems,
      totalCount: filtered.length,
      canLoadMore: paged.length < filtered.length,
    );
  }

  HistoryRevisionDetail? buildDetail({
    required EntityType entityType,
    required String revisionId,
    required List<_HistorySnapshot> history,
    required _HistorySnapshot? current,
  }) {
    final selected = _firstWhereOrNull(
      history,
      (snapshot) => snapshot.revisionId == revisionId,
    );
    if (selected == null) {
      return null;
    }

    return _buildDetail(
      entityType: entityType,
      selected: selected,
      history: history,
      current: current,
    );
  }

  Future<void> restoreRevision({
    required EntityType entityType,
    required String revisionId,
    required List<_HistorySnapshot> history,
  }) async {
    final snapshot = _firstWhereOrNull(
      history,
      (entry) => entry.revisionId == revisionId,
    );
    if (snapshot == null) {
      throw StateError('History revision not found.');
    }
    if (!snapshot.isRestorable) {
      throw StateError('Selected revision cannot be restored.');
    }

    final liveExists = await store.vaultItemDao.getById(
      snapshot.originalEntityId,
    );
    final recreate = liveExists == null;

    await store.transaction(() async {
      await _upsertVaultItem(snapshot, recreate: recreate);
      await _upsertTypeSpecific(entityType, snapshot, recreate: recreate);
      await store.customFieldDao.replaceAll(
        snapshot.originalEntityId,
        snapshot.customFields
            .map(
              (field) => CreateCustomFieldDto(
                label: field.label,
                value: field.value,
                fieldType: field.fieldType,
                sortOrder: field.sortOrder,
              ),
            )
            .toList(),
      );
    });
  }

  Future<bool> deleteRevision({
    required EntityType entityType,
    required String revisionId,
  }) async {
    final affected = switch (entityType) {
      EntityType.password =>
        await store.passwordHistoryDao.deletePasswordHistoryById(revisionId),
      EntityType.note => await store.noteHistoryDao.deleteNoteHistoryById(
        revisionId,
      ),
      EntityType.bankCard =>
        await store.bankCardHistoryDao.deleteBankCardHistoryById(revisionId),
      EntityType.file => await store.fileHistoryDao.deleteFileHistoryById(
        revisionId,
      ),
      EntityType.otp => await store.otpHistoryDao.deleteOtpHistoryById(
        revisionId,
      ),
      EntityType.document =>
        await store.documentHistoryDao.deleteDocumentHistoryById(revisionId),
      EntityType.contact =>
        await store.contactHistoryDao.deleteContactHistoryById(revisionId),
      EntityType.apiKey => await store.apiKeyHistoryDao.deleteApiKeyHistoryById(
        revisionId,
      ),
      EntityType.sshKey => await store.sshKeyHistoryDao.deleteSshKeyHistoryById(
        revisionId,
      ),
      EntityType.certificate =>
        await store.certificateHistoryDao.deleteCertificateHistoryById(
          revisionId,
        ),
      EntityType.cryptoWallet =>
        await store.cryptoWalletHistoryDao.deleteCryptoWalletHistoryById(
          revisionId,
        ),
      EntityType.wifi => await store.wifiHistoryDao.deleteWifiHistoryById(
        revisionId,
      ),
      EntityType.identity =>
        await store.identityHistoryDao.deleteIdentityHistoryById(revisionId),
      EntityType.licenseKey =>
        await store.licenseKeyHistoryDao.deleteLicenseKeyHistoryById(
          revisionId,
        ),
      EntityType.recoveryCodes =>
        await store.recoveryCodesHistoryDao.deleteRecoveryCodesHistoryById(
          revisionId,
        ),
      EntityType.loyaltyCard =>
        await store.loyaltyCardHistoryDao.deleteLoyaltyCardHistoryById(
          revisionId,
        ),
    };
    return affected > 0;
  }

  Future<bool> clearAllHistory({
    required EntityType entityType,
    required String entityId,
  }) async {
    final affected = switch (entityType) {
      EntityType.password =>
        await store.passwordHistoryDao.deletePasswordHistoryByPasswordId(
          entityId,
        ),
      EntityType.note => await store.noteHistoryDao.deleteNoteHistoryByNoteId(
        entityId,
      ),
      EntityType.bankCard =>
        await store.bankCardHistoryDao.deleteBankCardHistoryByOriginalId(
          entityId,
        ),
      EntityType.file => await store.fileHistoryDao.deleteFileHistoryByFileId(
        entityId,
      ),
      EntityType.otp => await store.otpHistoryDao.deleteOtpHistoryByOtpId(
        entityId,
      ),
      EntityType.document =>
        await store.documentHistoryDao.deleteDocumentHistoryByDocumentId(
          entityId,
        ),
      EntityType.contact =>
        await store.contactHistoryDao.deleteContactHistoryByContactId(entityId),
      EntityType.apiKey =>
        await store.apiKeyHistoryDao.deleteApiKeyHistoryByApiKeyId(entityId),
      EntityType.sshKey =>
        await store.sshKeyHistoryDao.deleteSshKeyHistoryBySshKeyId(entityId),
      EntityType.certificate =>
        await store.certificateHistoryDao
            .deleteCertificateHistoryByCertificateId(entityId),
      EntityType.cryptoWallet =>
        await store.cryptoWalletHistoryDao
            .deleteCryptoWalletHistoryByCryptoWalletId(entityId),
      EntityType.wifi => await store.wifiHistoryDao.deleteWifiHistoryByWifiId(
        entityId,
      ),
      EntityType.identity =>
        await store.identityHistoryDao.deleteIdentityHistoryByIdentityId(
          entityId,
        ),
      EntityType.licenseKey =>
        await store.licenseKeyHistoryDao.deleteLicenseKeyHistoryByLicenseKeyId(
          entityId,
        ),
      EntityType.recoveryCodes =>
        await store.recoveryCodesHistoryDao
            .deleteRecoveryCodesHistoryByRecoveryCodesId(entityId),
      EntityType.loyaltyCard =>
        await store.loyaltyCardHistoryDao.deleteLoyaltyCardHistoryByOriginalId(
          entityId,
        ),
    };
    return affected >= 0;
  }

  List<_HistorySnapshot> _applyFilters(
    List<_HistorySnapshot> history,
    HistoryQueryState query,
  ) {
    final search = query.search.trim().toLowerCase();
    final cutoff = switch (query.datePreset) {
      HistoryDatePreset.all => null,
      HistoryDatePreset.last7Days => DateTime.now().subtract(
        const Duration(days: 7),
      ),
      HistoryDatePreset.last30Days => DateTime.now().subtract(
        const Duration(days: 30),
      ),
    };

    return history.where((snapshot) {
      if (query.actionFilter == HistoryActionFilter.modified &&
          snapshot.action != ActionInHistory.modified.value) {
        return false;
      }
      if (query.actionFilter == HistoryActionFilter.deleted &&
          snapshot.action != ActionInHistory.deleted.value) {
        return false;
      }
      if (cutoff != null && snapshot.actionAt.isBefore(cutoff)) {
        return false;
      }
      if (search.isEmpty) {
        return true;
      }

      final haystack = <String?>[
        snapshot.title,
        snapshot.subtitle,
        snapshot.description,
        snapshot.categoryName,
        ...snapshot.fields.values.whereType<String>(),
        ...snapshot.customFields.map((field) => field.label),
        ...snapshot.customFields.map((field) => field.value),
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(search);
    }).toList();
  }

  HistoryRevisionDetail _buildDetail({
    required EntityType entityType,
    required _HistorySnapshot selected,
    required List<_HistorySnapshot> history,
    required _HistorySnapshot? current,
  }) {
    final selectedIndex = history.indexWhere(
      (snapshot) => snapshot.revisionId == selected.revisionId,
    );
    final newerRevision = selectedIndex > 0 ? history[selectedIndex - 1] : null;

    late final HistoryCompareTargetKind compareTargetKind;
    late final _HistorySnapshot compareTarget;

    if (newerRevision != null) {
      compareTargetKind = HistoryCompareTargetKind.newerRevision;
      compareTarget = newerRevision;
    } else if (current != null) {
      compareTargetKind = HistoryCompareTargetKind.currentLive;
      compareTarget = current;
    } else {
      compareTargetKind = HistoryCompareTargetKind.deletedState;
      compareTarget = _deletedStateFrom(selected);
    }

    return HistoryRevisionDetail(
      revisionId: selected.revisionId,
      snapshotTitle: selected.title,
      snapshotSubtitle: selected.subtitle,
      action: selected.action,
      actionAt: selected.actionAt,
      compareTargetKind: compareTargetKind,
      fieldDiffs: _buildFieldDiffs(
        entityType: entityType,
        current: selected,
        replacement: compareTarget,
      ),
      customFieldDiffs: _buildCustomFieldDiffs(
        current: selected,
        replacement: compareTarget,
      ),
      metadata: {
        'category': selected.categoryName,
        'createdAt': _normalizeValue(selected.originalCreatedAt),
        'modifiedAt': _normalizeValue(selected.originalModifiedAt),
        'lastUsedAt': _normalizeValue(selected.lastUsedAt),
      },
      restoreWarnings: selected.restoreWarnings,
      isRestorable: selected.isRestorable,
    );
  }

  List<HistoryFieldDiff> _buildFieldDiffs({
    required EntityType entityType,
    required _HistorySnapshot current,
    required _HistorySnapshot replacement,
  }) {
    final labels = _fieldLabels(entityType);
    final keys = {...current.fields.keys, ...replacement.fields.keys}.toList()
      ..sort();
    final diffs = <HistoryFieldDiff>[];

    for (final key in keys) {
      final oldValue = _normalizeValue(current.fields[key]);
      final newValue = _normalizeValue(replacement.fields[key]);
      if (oldValue == null && newValue == null) {
        continue;
      }
      if (oldValue == newValue) {
        continue;
      }

      final isSensitive =
          current.sensitiveKeys.contains(key) ||
          replacement.sensitiveKeys.contains(key);

      diffs.add(
        HistoryFieldDiff(
          fieldKey: key,
          label: labels[key] ?? key,
          oldValue: isSensitive ? t.history.hidden_value : oldValue,
          newValue: isSensitive ? t.history.hidden_value : newValue,
          changeType: switch ((oldValue, newValue)) {
            (null, _) => HistoryFieldChangeType.added,
            (_, null) => HistoryFieldChangeType.removed,
            _ => HistoryFieldChangeType.changed,
          },
          isSensitive: isSensitive,
        ),
      );
    }

    return diffs;
  }

  List<HistoryFieldDiff> _buildCustomFieldDiffs({
    required _HistorySnapshot current,
    required _HistorySnapshot replacement,
  }) {
    final currentMap = {
      for (final field in current.customFields) field.key: field,
    };
    final replacementMap = {
      for (final field in replacement.customFields) field.key: field,
    };
    final keys = {...currentMap.keys, ...replacementMap.keys}.toList()..sort();
    final diffs = <HistoryFieldDiff>[];

    for (final key in keys) {
      final oldField = currentMap[key];
      final newField = replacementMap[key];
      final oldValue = _normalizeValue(oldField?.value);
      final newValue = _normalizeValue(newField?.value);
      if (oldValue == null && newValue == null) {
        continue;
      }
      if (oldValue == newValue && oldField?.label == newField?.label) {
        continue;
      }
      final fieldType = oldField?.fieldType ?? newField?.fieldType;
      final isSensitive = fieldType == CustomFieldType.concealed;
      diffs.add(
        HistoryFieldDiff(
          fieldKey: key,
          label: oldField?.label ?? newField?.label ?? t.history.custom_field,
          oldValue: isSensitive ? t.history.hidden_value : oldValue,
          newValue: isSensitive ? t.history.hidden_value : newValue,
          changeType: switch ((oldValue, newValue)) {
            (null, _) => HistoryFieldChangeType.added,
            (_, null) => HistoryFieldChangeType.removed,
            _ => HistoryFieldChangeType.changed,
          },
          isSensitive: isSensitive,
        ),
      );
    }

    return diffs;
  }

  _HistorySnapshot _deletedStateFrom(_HistorySnapshot snapshot) {
    return snapshot.copyWith(
      action: ActionInHistory.deleted.value,
      fields: {...snapshot.fields, 'deleted': true},
      isRestorable: false,
      restoreWarnings: snapshot.restoreWarnings,
    );
  }

  Map<String, String> _fieldLabels(EntityType entityType) {
    final forms = t.dashboard_forms;
    final base = <String, String>{
      'name': forms.name_label,
      'description': forms.description_label,
      'category': forms.category_label,
      'usedCount': t.history.used_count,
      'favorite': t.history.favorite_flag,
      'archived': t.history.archived_flag,
      'pinned': t.history.pinned_flag,
      'deleted': t.history.deleted_flag,
    };

    switch (entityType) {
      case EntityType.password:
        return {
          ...base,
          'login': forms.login_label,
          'email': forms.email_field_label,
          'password': forms.password_label,
          'url': forms.url_label,
          'expireAt': forms.expiration_date_label,
        };
      case EntityType.note:
        return {...base, 'content': t.history.note_content};
      case EntityType.bankCard:
        return {
          ...base,
          'cardholderName': forms.cardholder_name_label,
          'cardNumber': forms.card_number_label,
          'expiryMonth': forms.expiry_month_label,
          'expiryYear': forms.expiry_year_label,
          'bankName': forms.bank_name_label,
          'accountNumber': forms.account_number_label,
          'cvv': t.history.cvv,
          'routingNumber': t.history.routing_number,
          'cardType': t.history.card_type,
          'cardNetwork': t.history.card_network,
        };
      case EntityType.file:
        return {
          ...base,
          'metadataId': t.history.file_version,
          'fileName': t.history.file_name,
          'fileExtension': t.history.file_extension,
          'mimeType': t.history.mime_type,
          'fileSize': t.history.file_size,
          'filePath': t.history.file_path,
        };
      case EntityType.otp:
        return {
          ...base,
          'otpType': t.history.otp_type,
          'issuer': forms.issuer_label,
          'accountName': forms.otp_account_name_label,
          'secret': forms.otp_secret_key_label,
          'secretEncoding': t.history.secret_encoding,
          'algorithm': forms.algorithm_label,
          'digits': forms.digits_count_label,
          'period': forms.period_seconds_label,
          'counter': t.history.counter,
          'passwordItemId': t.history.linked_password,
        };
      case EntityType.document:
        return {
          ...base,
          'documentType': t.history.document_type,
          'aggregatedText': t.history.document_text,
          'pageCount': t.history.page_count,
        };
      case EntityType.contact:
        return {
          ...base,
          'phone': forms.phone_label,
          'email': forms.email_field_label,
          'company': forms.company_label,
          'jobTitle': forms.job_title_label,
          'address': forms.address_label,
          'website': forms.website_label,
          'birthday': forms.birthday_label,
          'isEmergencyContact': forms.emergency_contact_label,
        };
      case EntityType.apiKey:
        return {
          ...base,
          'service': forms.api_key_service_label,
          'key': forms.api_key_key_label,
          'maskedKey': forms.api_key_label,
          'tokenType': forms.api_key_token_type_label,
          'environment': forms.api_key_environment_label,
          'expiresAt': forms.expiration_date_label,
          'revoked': forms.api_key_revoked_label,
          'rotationPeriodDays': t.history.rotation_period_days,
          'lastRotatedAt': t.history.last_rotated_at,
          'metadata': t.history.metadata,
        };
      case EntityType.sshKey:
        return {
          ...base,
          'publicKey': forms.public_key_required_label,
          'privateKey': forms.private_key_required_label,
          'keyType': forms.key_type_label,
          'keySize': t.history.key_size,
          'passphraseHint': t.history.passphrase_hint,
          'comment': t.history.comment,
          'fingerprint': forms.fingerprint_label,
          'createdBy': t.history.created_by,
          'addedToAgent': forms.added_to_ssh_agent_label,
          'usage': forms.usage_label,
          'publicKeyFileId': t.history.public_key_file_id,
          'privateKeyFileId': t.history.private_key_file_id,
          'metadata': t.history.metadata,
        };
      case EntityType.certificate:
        return {
          ...base,
          'certificatePem': forms.certificate_pem_label,
          'privateKey': forms.private_key_label,
          'serialNumber': forms.serial_number_label,
          'issuer': forms.issuer_label,
          'subject': forms.subject_label,
          'validFrom': t.history.valid_from,
          'validTo': t.history.valid_to,
          'fingerprint': forms.fingerprint_label,
          'keyUsage': t.history.key_usage,
          'extensions': t.history.extensions,
          'pfxBlob': t.history.pfx,
          'passwordForPfx': forms.pfx_password_label,
          'ocspUrl': forms.ocsp_url_label,
          'crlUrl': forms.crl_url_label,
          'autoRenew': forms.auto_renew_label,
          'lastCheckedAt': t.history.last_checked_at,
        };
      case EntityType.cryptoWallet:
        return {
          ...base,
          'walletType': forms.wallet_type_label,
          'mnemonic': forms.mnemonic_label,
          'privateKey': forms.private_key_label,
          'derivationPath': forms.derivation_path_label,
          'network': forms.network_label,
          'addresses': forms.addresses_json_label,
          'xpub': forms.xpub_label,
          'xprv': forms.xprv_label,
          'hardwareDevice': forms.hardware_device_label,
          'lastBalanceCheckedAt': t.history.last_balance_checked_at,
          'watchOnly': forms.watch_only_label,
          'derivationScheme': forms.derivation_scheme_label,
        };
      case EntityType.wifi:
        return {
          ...base,
          'ssid': forms.wifi_ssid_label,
          'password': forms.wifi_password_label,
          'security': forms.wifi_security_label,
          'hidden': forms.wifi_hidden_network_label,
          'eapMethod': forms.wifi_eap_method_label,
          'username': forms.wifi_username_label,
          'identity': forms.wifi_identity_label,
          'domain': forms.wifi_domain_label,
          'lastConnectedBssid': forms.wifi_last_connected_bssid_label,
          'priority': forms.wifi_priority_label,
          'qrCodePayload': forms.wifi_qr_payload_label,
        };
      case EntityType.identity:
        return {
          ...base,
          'idType': t.history.id_type,
          'idNumber': t.history.id_number,
          'fullName': forms.full_name_label,
          'dateOfBirth': forms.birth_date_iso_label,
          'placeOfBirth': forms.place_of_birth_label,
          'nationality': forms.nationality_label,
          'issuingAuthority': forms.issuing_authority_label,
          'issueDate': forms.issue_date_iso_label,
          'expiryDate': forms.expiry_date_iso_label,
          'mrz': forms.mrz_label,
          'scanAttachmentId': forms.scan_id_label,
          'photoAttachmentId': forms.photo_id_label,
          'verified': forms.verified_label,
        };
      case EntityType.licenseKey:
        return {
          ...base,
          'product': forms.product_label,
          'licenseKey': forms.license_key_label,
          'licenseType': forms.license_type_label,
          'seats': forms.seats_count_label,
          'maxActivations': forms.max_activations_label,
          'activatedOn': forms.activated_at_iso_label,
          'purchaseDate': forms.purchase_date_iso_label,
          'purchaseFrom': forms.purchased_from_label,
          'orderId': forms.order_id_label,
          'licenseFileId': forms.license_file_id_label,
          'expiresAt': forms.expiration_date_label,
          'supportContact': forms.support_contact_label,
        };
      case EntityType.recoveryCodes:
        return {
          ...base,
          'codesCount': forms.total_codes_label,
          'usedCountCodes': forms.used_codes_label,
          'oneTime': forms.one_time_codes_label,
          'displayHint': forms.display_hint_label,
        };
      case EntityType.loyaltyCard:
        return {
          ...base,
          'programName': forms.program_name_label,
          'cardNumber': forms.loyalty_card_number_label,
          'holderName': forms.holder_name_label,
          'barcodeValue': forms.barcode_value_label,
          'barcodeType': forms.barcode_type_label,
          'password': forms.pin_password_label,
          'pointsBalance': forms.points_balance_label,
          'tier': forms.tier_label,
          'expiryDate': forms.expiry_date_iso_label,
          'website': forms.website_label,
          'phoneNumber': forms.phone_label,
        };
    }
  }

  String? _normalizeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is bool) {
      return value ? t.dashboard_forms.common_yes : t.dashboard_forms.common_no;
    }
    if (value is Uint8List) {
      return '${t.history.binary_value} (${value.length} B)';
    }
    if (value is List<int>) {
      return '${t.history.binary_value} (${value.length} B)';
    }
    return '$value';
  }

  List<String> _genericWarnings() {
    return [t.history.tags_not_in_history, t.history.note_link_not_in_history];
  }
}

class _HistoryLoadResult {
  const _HistoryLoadResult({
    required this.history,
    required this.current,
    required this.timelineItems,
    required this.totalCount,
    required this.canLoadMore,
  });

  final List<_HistorySnapshot> history;
  final _HistorySnapshot? current;
  final List<HistoryTimelineItem> timelineItems;
  final int totalCount;
  final bool canLoadMore;
}

class _HistorySnapshot {
  const _HistorySnapshot({
    required this.entityType,
    required this.revisionId,
    required this.originalEntityId,
    required this.action,
    required this.actionAt,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.fields,
    required this.sensitiveKeys,
    required this.usedCount,
    required this.isFavorite,
    required this.isArchived,
    required this.isPinned,
    required this.isDeleted,
    required this.recentScore,
    required this.lastUsedAt,
    required this.originalCreatedAt,
    required this.originalModifiedAt,
    required this.customFields,
    required this.restoreWarnings,
    required this.isRestorable,
  });

  final EntityType entityType;
  final String revisionId;
  final String originalEntityId;
  final String action;
  final DateTime actionAt;
  final String title;
  final String? subtitle;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final Map<String, Object?> fields;
  final Set<String> sensitiveKeys;
  final int usedCount;
  final bool isFavorite;
  final bool isArchived;
  final bool isPinned;
  final bool isDeleted;
  final double? recentScore;
  final DateTime? lastUsedAt;
  final DateTime? originalCreatedAt;
  final DateTime? originalModifiedAt;
  final List<HistoryCustomFieldValue> customFields;
  final List<String> restoreWarnings;
  final bool isRestorable;

  _HistorySnapshot copyWith({
    String? action,
    Map<String, Object?>? fields,
    bool? isRestorable,
    List<String>? restoreWarnings,
  }) {
    return _HistorySnapshot(
      entityType: entityType,
      revisionId: revisionId,
      originalEntityId: originalEntityId,
      action: action ?? this.action,
      actionAt: actionAt,
      title: title,
      subtitle: subtitle,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      fields: fields ?? this.fields,
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
      restoreWarnings: restoreWarnings ?? this.restoreWarnings,
      isRestorable: isRestorable ?? this.isRestorable,
    );
  }
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) {
      return value;
    }
  }
  return null;
}
