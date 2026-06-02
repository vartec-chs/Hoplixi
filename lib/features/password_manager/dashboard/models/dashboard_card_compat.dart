import 'package:hoplixi/vault_db/core/models/dto/api_key_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/bank_card_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/certificate_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/contact_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/crypto_wallet_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/document_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/file_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/filter_meta_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/identity_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/license_key_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/note_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/otp_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/ssh_key_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/wifi_dto.dart';

sealed class BaseCardDto {
  const BaseCardDto();

  String get id;
  String get name;
  String get description;
  String get displayName;
  bool get isFavorite;
  bool get isPinned;
  bool get isArchived;
  bool get isDeleted;
  DateTime? get createdAt;
  DateTime? get modifiedAt;
  DateTime? get lastUsedAt;
  CategoryInCardDto? get category;
  List<TagInCardDto> get tags;
  String? get iconSource;
  String? get iconValue;
  int get usedCount;

  BaseCardDto withBase({
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
  });
}

abstract class _CardEntry<T extends VaultEntityCardDto> extends BaseCardDto {
  const _CardEntry();

  FilteredCardDto<T> get data;

  VaultItemCardDto get _item => data.card.item;
  VaultItemCardMetaDto get _meta => data.meta;

  @override
  String get id => _item.itemId;
  @override
  String get name => _item.name;
  @override
  String get description => _item.description ?? '';
  @override
  String get displayName => _item.name;
  @override
  bool get isFavorite => _item.isFavorite;
  @override
  bool get isPinned => _item.isPinned;
  @override
  bool get isArchived => _item.isArchived;
  @override
  bool get isDeleted => _item.isDeleted;
  @override
  DateTime? get createdAt => _item.createdAt;
  @override
  DateTime? get modifiedAt => _item.modifiedAt;
  @override
  DateTime? get lastUsedAt => _item.lastUsedAt;
  @override
  CategoryInCardDto? get category => _meta.category;
  @override
  List<TagInCardDto> get tags => _meta.tags;
  @override
  String? get iconSource => null;
  @override
  String? get iconValue => null;
  @override
  int get usedCount => 0;

  @override
  BaseCardDto withBase({
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
  }) {
    final newItem = data.card.item.copyWith(
      isFavorite: isFavorite ?? _item.isFavorite,
      isPinned: isPinned ?? _item.isPinned,
      isArchived: isArchived ?? _item.isArchived,
      isDeleted: isDeleted ?? _item.isDeleted,
    );
    return _rebuildWith(
      newItem: newItem,
      category: category ?? _meta.category,
      tags: tags ?? _meta.tags,
    );
  }

  _CardEntry<T> _rebuildWith({
    required VaultItemCardDto newItem,
    required CategoryInCardDto? category,
    required List<TagInCardDto> tags,
  });
}

BaseCardDto wrapCard<T extends VaultEntityCardDto>(FilteredCardDto<T> data) {
  return switch (data.card) {
    PasswordCardDto() => PasswordCardEntry(
        data: data as FilteredCardDto<PasswordCardDto>,
      ),
    NoteCardDto() => NoteCardEntry(
        data: data as FilteredCardDto<NoteCardDto>,
      ),
    BankCardCardDto() => BankCardEntry(
        data: data as FilteredCardDto<BankCardCardDto>,
      ),
    FileCardDto() => FileCardEntry(
        data: data as FilteredCardDto<FileCardDto>,
      ),
    OtpCardDto() => OtpCardEntry(
        data: data as FilteredCardDto<OtpCardDto>,
      ),
    DocumentCardDto() => DocumentCardEntry(
        data: data as FilteredCardDto<DocumentCardDto>,
      ),
    ContactCardDto() => ContactCardEntry(
        data: data as FilteredCardDto<ContactCardDto>,
      ),
    ApiKeyCardDto() => ApiKeyCardEntry(
        data: data as FilteredCardDto<ApiKeyCardDto>,
      ),
    SshKeyCardDto() => SshKeyCardEntry(
        data: data as FilteredCardDto<SshKeyCardDto>,
      ),
    CertificateCardDto() => CertificateCardEntry(
        data: data as FilteredCardDto<CertificateCardDto>,
      ),
    CryptoWalletCardDto() => CryptoWalletCardEntry(
        data: data as FilteredCardDto<CryptoWalletCardDto>,
      ),
    WifiCardDto() => WifiCardEntry(
        data: data as FilteredCardDto<WifiCardDto>,
      ),
    IdentityCardDto() => IdentityCardEntry(
        data: data as FilteredCardDto<IdentityCardDto>,
      ),
    LicenseKeyCardDto() => LicenseKeyCardEntry(
        data: data as FilteredCardDto<LicenseKeyCardDto>,
      ),
    RecoveryCodesCardDto() => RecoveryCodesCardEntry(
        data: data as FilteredCardDto<RecoveryCodesCardDto>,
      ),
    LoyaltyCardCardDto() => LoyaltyCardEntry(
        data: data as FilteredCardDto<LoyaltyCardCardDto>,
      ),
    _ => throw UnimplementedError('Unknown card type: ${data.card.runtimeType}'),
  };
}

final class PasswordCardEntry extends _CardEntry<PasswordCardDto> {
  const PasswordCardEntry({required this.data});
  @override
  final FilteredCardDto<PasswordCardDto> data;

  @override
  PasswordCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return PasswordCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class NoteCardEntry extends _CardEntry<NoteCardDto> {
  const NoteCardEntry({required this.data});
  @override
  final FilteredCardDto<NoteCardDto> data;

  @override
  NoteCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return NoteCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class BankCardEntry extends _CardEntry<BankCardCardDto> {
  const BankCardEntry({required this.data});
  @override
  final FilteredCardDto<BankCardCardDto> data;

  @override
  BankCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return BankCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class FileCardEntry extends _CardEntry<FileCardDto> {
  const FileCardEntry({required this.data});
  @override
  final FilteredCardDto<FileCardDto> data;

  @override
  FileCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return FileCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class OtpCardEntry extends _CardEntry<OtpCardDto> {
  const OtpCardEntry({required this.data});
  @override
  final FilteredCardDto<OtpCardDto> data;

  @override
  OtpCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return OtpCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class DocumentCardEntry extends _CardEntry<DocumentCardDto> {
  const DocumentCardEntry({required this.data});
  @override
  final FilteredCardDto<DocumentCardDto> data;

  @override
  DocumentCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return DocumentCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class ContactCardEntry extends _CardEntry<ContactCardDto> {
  const ContactCardEntry({required this.data});
  @override
  final FilteredCardDto<ContactCardDto> data;

  @override
  ContactCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return ContactCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class ApiKeyCardEntry extends _CardEntry<ApiKeyCardDto> {
  const ApiKeyCardEntry({required this.data});
  @override
  final FilteredCardDto<ApiKeyCardDto> data;

  @override
  ApiKeyCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return ApiKeyCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class SshKeyCardEntry extends _CardEntry<SshKeyCardDto> {
  const SshKeyCardEntry({required this.data});
  @override
  final FilteredCardDto<SshKeyCardDto> data;

  @override
  SshKeyCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return SshKeyCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class CertificateCardEntry extends _CardEntry<CertificateCardDto> {
  const CertificateCardEntry({required this.data});
  @override
  final FilteredCardDto<CertificateCardDto> data;

  @override
  CertificateCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return CertificateCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class CryptoWalletCardEntry extends _CardEntry<CryptoWalletCardDto> {
  const CryptoWalletCardEntry({required this.data});
  @override
  final FilteredCardDto<CryptoWalletCardDto> data;

  @override
  CryptoWalletCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return CryptoWalletCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class WifiCardEntry extends _CardEntry<WifiCardDto> {
  const WifiCardEntry({required this.data});
  @override
  final FilteredCardDto<WifiCardDto> data;

  @override
  WifiCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return WifiCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class IdentityCardEntry extends _CardEntry<IdentityCardDto> {
  const IdentityCardEntry({required this.data});
  @override
  final FilteredCardDto<IdentityCardDto> data;

  @override
  IdentityCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return IdentityCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class LicenseKeyCardEntry extends _CardEntry<LicenseKeyCardDto> {
  const LicenseKeyCardEntry({required this.data});
  @override
  final FilteredCardDto<LicenseKeyCardDto> data;

  @override
  LicenseKeyCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return LicenseKeyCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class RecoveryCodesCardEntry extends _CardEntry<RecoveryCodesCardDto> {
  const RecoveryCodesCardEntry({required this.data});
  @override
  final FilteredCardDto<RecoveryCodesCardDto> data;

  @override
  RecoveryCodesCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return RecoveryCodesCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}

final class LoyaltyCardEntry extends _CardEntry<LoyaltyCardCardDto> {
  const LoyaltyCardEntry({required this.data});
  @override
  final FilteredCardDto<LoyaltyCardCardDto> data;

  @override
  LoyaltyCardEntry _rebuildWith({required VaultItemCardDto newItem, required CategoryInCardDto? category, required List<TagInCardDto> tags}) {
    return LoyaltyCardEntry(
      data: data.copyWith(
        card: data.card.copyWith(item: newItem),
        meta: data.meta.copyWith(category: category, tags: tags),
      ),
    );
  }
}
