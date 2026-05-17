import 'package:result_dart/result_dart.dart';

import '../../errors/db_result.dart';
import '../../models/dto_history/cards/cards_exports.dart';
import '../../models/filters/history/vault_snapshot_history_filter.dart';
import '../../tables/vault_items/vault_events_history.dart';
import 'policy/vault_history_restore_policy_service.dart';
import 'vault_history_detail_service.dart';
import 'vault_history_read_service.dart';
import 'models/vault_history_timeline_diff_mode.dart';

class _TimelineDiffSummary {
  const _TimelineDiffSummary({
    required this.changedFieldsCount,
    required this.changedFieldLabels,
  });

  final int changedFieldsCount;
  final List<String> changedFieldLabels;

  static const empty = _TimelineDiffSummary(
    changedFieldsCount: 0,
    changedFieldLabels: <String>[],
  );
}

class VaultHistoryTimelineService {
  VaultHistoryTimelineService({
    required this.readService,
    required this.detailService,
    required this.restorePolicyService,
  });

  final VaultHistoryReadService readService;
  final VaultHistoryDetailService detailService;
  final VaultHistoryRestorePolicyService restorePolicyService;

  Future<DbResult<List<VaultHistoryTimelineItemDto>>> getTimeline(
    VaultSnapshotHistoryFilter filter, {
    VaultHistoryTimelineDiffMode diffMode =
        VaultHistoryTimelineDiffMode.lightweight,
  }) async {
    final cardsRes = await readService.getFilteredCards(filter);
    if (cardsRes.isError()) {
      return Failure(cardsRes.exceptionOrNull()!);
    }

    final cards = cardsRes.getOrNull() ?? [];

    final timelineItems = <VaultHistoryTimelineItemDto>[];
    for (final card in cards) {
      final item = await _buildTimelineItem(card, diffMode: diffMode);
      timelineItems.add(item);
    }

    return Success(timelineItems);
  }

  Future<VaultHistoryTimelineItemDto> _buildTimelineItem(
    VaultHistoryCardDto card, {
    required VaultHistoryTimelineDiffMode diffMode,
  }) async {
    final snapshot = card.snapshot;
    final diffSummary = await _buildDiffSummary(card, diffMode: diffMode);

    return VaultHistoryTimelineItemDto(
      historyId: snapshot.historyId,
      itemId: snapshot.itemId,
      type: snapshot.type,
      action: snapshot.action,
      title: _buildTitle(card),
      subtitle: _buildSubtitle(card),
      actionAt: snapshot.historyCreatedAt,
      changedFieldsCount: diffSummary.changedFieldsCount,
      changedFieldLabels: diffSummary.changedFieldLabels,
      isRestorable: _isRestorable(card),
      restoreWarnings: _restoreWarnings(card),
    );
  }

  Future<_TimelineDiffSummary> _buildDiffSummary(
    VaultHistoryCardDto card, {
    required VaultHistoryTimelineDiffMode diffMode,
  }) async {
    switch (diffMode) {
      case VaultHistoryTimelineDiffMode.none:
        return _TimelineDiffSummary.empty;

      case VaultHistoryTimelineDiffMode.lightweight:
        return _buildLightweightDiffSummary(card);

      case VaultHistoryTimelineDiffMode.full:
        return await _buildFullDiffSummary(card);
    }
  }

  _TimelineDiffSummary _buildLightweightDiffSummary(VaultHistoryCardDto card) {
    final actionLabels = _actionLabels(card.snapshot.action);
    final labels = actionLabels.isNotEmpty
        ? actionLabels
        : _typeSpecificLightweightLabels(card);

    return _TimelineDiffSummary(
      changedFieldsCount: labels.length,
      changedFieldLabels: labels.take(3).toList(),
    );
  }

  Future<_TimelineDiffSummary> _buildFullDiffSummary(
    VaultHistoryCardDto card,
  ) async {
    final detailRes = await detailService.getRevisionDetail(
      historyId: card.snapshot.historyId,
    );

    if (detailRes.isError()) {
      return _buildLightweightDiffSummary(card);
    }

    final detail = detailRes.getOrNull();
    if (detail == null) {
      return _buildLightweightDiffSummary(card);
    }

    final diffs = [...detail.fieldDiffs, ...detail.customFieldDiffs];

    return _TimelineDiffSummary(
      changedFieldsCount: diffs.length,
      changedFieldLabels: diffs
          .map((d) => d.label)
          .where((label) => label.trim().isNotEmpty)
          .take(3)
          .toList(),
    );
  }

  List<String> _actionLabels(VaultEventHistoryAction action) {
    switch (action) {
      case VaultEventHistoryAction.created:
        return const ['Создание'];
      case VaultEventHistoryAction.deleted:
        return const ['Удаление'];
      case VaultEventHistoryAction.archived:
        return const ['Архивация'];
      case VaultEventHistoryAction.restored:
        return const ['Восстановление'];
      case VaultEventHistoryAction.recovered:
        return const ['Восстановление из корзины'];
      case VaultEventHistoryAction.favorited:
      case VaultEventHistoryAction.unfavorited:
        return const ['Избранное'];
      case VaultEventHistoryAction.pinned:
      case VaultEventHistoryAction.unpinned:
        return const ['Закрепление'];
      case VaultEventHistoryAction.used:
        return const ['Использование'];
      case VaultEventHistoryAction.movedToCategory:
        return const ['Изменение категории'];
      case VaultEventHistoryAction.categoryRemoved:
        return const ['Удаление из категории'];
      case VaultEventHistoryAction.iconChanged:
        return const ['Изменение иконки'];
      case VaultEventHistoryAction.iconRemoved:
        return const ['Удаление иконки'];
      case VaultEventHistoryAction.customFieldAdded:
        return const ['Добавлено поле'];
      case VaultEventHistoryAction.customFieldUpdated:
        return const ['Обновлено поле'];
      case VaultEventHistoryAction.customFieldDeleted:
        return const ['Удалено поле'];
      case VaultEventHistoryAction.customFieldReordered:
        return const ['Изменен порядок полей'];
      case VaultEventHistoryAction.updated:
        return const [];
    }
  }

  List<String> _typeSpecificLightweightLabels(VaultHistoryCardDto card) {
    if (card is ApiKeyHistoryCardDto) {
      return const ['Service', 'Environment', 'Expiration'];
    } else if (card is PasswordHistoryCardDto) {
      return const ['Login', 'Email', 'URL', 'Expiration'];
    } else if (card is BankCardHistoryCardDto) {
      return const ['Cardholder', 'Expiry', 'Bank'];
    } else if (card is CertificateHistoryCardDto) {
      return const ['Subject', 'Issuer', 'Validity'];
    } else if (card is ContactHistoryCardDto) {
      return const ['Email', 'Phone', 'Company'];
    } else if (card is CryptoWalletHistoryCardDto) {
      return const ['Wallet type', 'Network', 'Addresses'];
    } else if (card is FileHistoryCardDto) {
      return const ['File name', 'Availability', 'Integrity'];
    } else if (card is IdentityHistoryCardDto) {
      return const ['Name', 'Email', 'Documents'];
    } else if (card is LicenseKeyHistoryCardDto) {
      return const ['Product', 'Vendor', 'Validity'];
    } else if (card is LoyaltyCardHistoryCardDto) {
      return const ['Program', 'Issuer', 'Validity'];
    } else if (card is NoteHistoryCardDto) {
      return const ['Content'];
    } else if (card is OtpHistoryCardDto) {
      return const ['Issuer', 'Account', 'Algorithm'];
    } else if (card is RecoveryCodesHistoryCardDto) {
      return const ['Codes count', 'Used count'];
    } else if (card is SshKeyHistoryCardDto) {
      return const ['Key type', 'Key size', 'Public key'];
    } else if (card is WifiHistoryCardDto) {
      return const ['SSID', 'Security', 'Hidden'];
    } else {
      return const ['Данные записи'];
    }
  }

  bool _isRestorable(VaultHistoryCardDto card) {
    return restorePolicyService.isCardRestorable(card);
  }

  List<String> _restoreWarnings(VaultHistoryCardDto card) {
    return restorePolicyService.restoreWarningsForCard(card);
  }

  String _buildTitle(VaultHistoryCardDto card) {
    return card.snapshot.name;
  }

  String? _buildSubtitle(VaultHistoryCardDto card) {
    final description = card.snapshot.description;
    if (description != null && description.trim().isNotEmpty) {
      return description;
    }

    if (card is ApiKeyHistoryCardDto) return card.apikey.service;
    if (card is PasswordHistoryCardDto) {
      final pwd = card.password;
      return pwd.login ?? pwd.email ?? pwd.url;
    }
    if (card is BankCardHistoryCardDto) {
      return card.bankcard.bankName ?? card.bankcard.cardholderName;
    }
    if (card is CertificateHistoryCardDto) {
      return card.certificate.subject ?? card.certificate.issuer;
    }
    if (card is ContactHistoryCardDto) {
      return card.contact.email ?? card.contact.phone ?? card.contact.company;
    }
    if (card is CryptoWalletHistoryCardDto) {
      final w = card.cryptowallet;
      return w.network?.name ?? w.walletType?.name;
    }
    if (card is FileHistoryCardDto) return card.file.fileName;
    if (card is IdentityHistoryCardDto) {
      final id = card.identity;
      return id.displayName ?? id.email ?? id.phone;
    }
    if (card is LicenseKeyHistoryCardDto) {
      return card.licensekey.productName ?? card.licensekey.vendor;
    }
    if (card is LoyaltyCardHistoryCardDto) {
      return card.loyaltycard.programName ?? card.loyaltycard.issuer;
    }
    if (card is NoteHistoryCardDto) return 'Заметка';
    if (card is OtpHistoryCardDto) {
      return card.otp.issuer ?? card.otp.accountName;
    }
    if (card is RecoveryCodesHistoryCardDto) {
      return '${card.recoverycodes.codesCount} кодов';
    }
    if (card is SshKeyHistoryCardDto) return card.sshkey.keyType?.name;
    if (card is WifiHistoryCardDto) return card.wifi.ssid;

    return null;
  }
}
