/// Тип элемента хранилища (vault item).
///
/// Определяет, какая type-specific таблица содержит
/// дополнительные поля для данного элемента.
enum VaultItemType { password, otp, note, bankCard, document, file }

extension VaultItemTypeX on VaultItemType {
  String get value {
    switch (this) {
      case VaultItemType.password:
        return 'password';
      case VaultItemType.otp:
        return 'otp';
      case VaultItemType.note:
        return 'note';
      case VaultItemType.bankCard:
        return 'bankCard';
      case VaultItemType.document:
        return 'document';
      case VaultItemType.file:
        return 'file';
    }
  }

  static VaultItemType fromString(String value) {
    switch (value) {
      case 'password':
        return VaultItemType.password;
      case 'otp':
        return VaultItemType.otp;
      case 'note':
        return VaultItemType.note;
      case 'bankCard':
        return VaultItemType.bankCard;
      case 'document':
        return VaultItemType.document;
      case 'file':
        return VaultItemType.file;
      default:
        throw ArgumentError('Invalid VaultItemType value: $value');
    }
  }
}

enum CategoryType { note, password, totp, bankCard, file, document, mixed }

enum TagType { note, password, totp, bankCard, file, document, mixed }

enum OtpType { totp, hotp }

enum ActionInHistory { created, deleted, modified }

enum IconType { png, jpg, svg, gif, bmp, webp }

enum AlgorithmOtp { SHA1, SHA256, SHA512 }

enum SecretEncoding { BASE32, HEX, BINARY }

enum CardType { debit, credit, prepaid, virtual }

enum CardNetwork {
  visa,
  mastercard,
  amex,
  discover,
  dinersclub,
  jcb,
  unionpay,
  other,
}

extension ActionInHistoryX on ActionInHistory {
  String get value {
    switch (this) {
      case ActionInHistory.created:
        return 'created';
      case ActionInHistory.deleted:
        return 'deleted';
      case ActionInHistory.modified:
        return 'modified';
    }
  }

  static ActionInHistory fromString(String value) {
    switch (value) {
      case 'created':
        return ActionInHistory.created;
      case 'deleted':
        return ActionInHistory.deleted;
      case 'modified':
        return ActionInHistory.modified;
      default:
        throw ArgumentError('Invalid ActionInHistory value: $value');
    }
  }
}

extension CategoryTypeX on CategoryType {
  String get value {
    switch (this) {
      case CategoryType.note:
        return 'note';
      case CategoryType.password:
        return 'password';
      case CategoryType.totp:
        return 'totp';
      case CategoryType.bankCard:
        return 'bankCard';
      case CategoryType.file:
        return 'file';
      case CategoryType.document:
        return 'document';
      case CategoryType.mixed:
        return 'mixed';
    }
  }

  static CategoryType fromString(String value) {
    switch (value) {
      case 'note':
        return CategoryType.note;
      case 'password':
        return CategoryType.password;
      case 'totp':
        return CategoryType.totp;
      case 'bankCard':
        return CategoryType.bankCard;
      case 'file':
        return CategoryType.file;
      case 'document':
        return CategoryType.document;
      case 'mixed':
        return CategoryType.mixed;
      default:
        throw ArgumentError('Invalid CategoryType value: $value');
    }
  }
}

extension TagTypeX on TagType {
  String get value {
    switch (this) {
      case TagType.note:
        return 'note';
      case TagType.password:
        return 'password';
      case TagType.totp:
        return 'totp';
      case TagType.bankCard:
        return 'bankCard';
      case TagType.file:
        return 'file';
      case TagType.document:
        return 'document';
      case TagType.mixed:
        return 'mixed';
    }
  }

  static TagType fromString(String value) {
    switch (value) {
      case 'note':
        return TagType.note;
      case 'password':
        return TagType.password;
      case 'totp':
        return TagType.totp;
      case 'bankCard':
        return TagType.bankCard;
      case 'file':
        return TagType.file;
      case 'document':
        return TagType.document;
      case 'mixed':
        return TagType.mixed;
      default:
        throw ArgumentError('Invalid TagType value: $value');
    }
  }
}

extension OtpTypeX on OtpType {
  String get value {
    switch (this) {
      case OtpType.totp:
        return 'totp';
      case OtpType.hotp:
        return 'hotp';
    }
  }

  static OtpType fromString(String value) {
    switch (value) {
      case 'totp':
        return OtpType.totp;
      case 'hotp':
        return OtpType.hotp;
      default:
        throw ArgumentError('Invalid OtpType value: $value');
    }
  }
}

extension IconTypeX on IconType {
  String get value {
    switch (this) {
      case IconType.png:
        return 'png';
      case IconType.jpg:
        return 'jpg';
      case IconType.svg:
        return 'svg';
      case IconType.gif:
        return 'gif';
      case IconType.bmp:
        return 'bmp';
      case IconType.webp:
        return 'webp';
    }
  }

  static IconType fromString(String value) {
    switch (value) {
      case 'png':
        return IconType.png;
      case 'jpg':
        return IconType.jpg;
      case 'svg':
        return IconType.svg;
      case 'gif':
        return IconType.gif;
      case 'bmp':
        return IconType.bmp;
      case 'webp':
        return IconType.webp;
      default:
        throw ArgumentError('Invalid IconType value: $value');
    }
  }
}

extension AlgorithmOtpX on AlgorithmOtp {
  String get value {
    switch (this) {
      case AlgorithmOtp.SHA1:
        return 'SHA1';
      case AlgorithmOtp.SHA256:
        return 'SHA256';
      case AlgorithmOtp.SHA512:
        return 'SHA512';
    }
  }

  static AlgorithmOtp fromString(String value) {
    switch (value) {
      case 'SHA1':
        return AlgorithmOtp.SHA1;
      case 'SHA256':
        return AlgorithmOtp.SHA256;
      case 'SHA512':
        return AlgorithmOtp.SHA512;
      default:
        throw ArgumentError('Invalid AlgorithmOtp value: $value');
    }
  }
}

extension SecretEncodingX on SecretEncoding {
  String get value {
    switch (this) {
      case SecretEncoding.BASE32:
        return 'BASE32';
      case SecretEncoding.HEX:
        return 'HEX';
      case SecretEncoding.BINARY:
        return 'BINARY';
    }
  }

  static SecretEncoding fromString(String value) {
    switch (value) {
      case 'BASE32':
        return SecretEncoding.BASE32;
      case 'HEX':
        return SecretEncoding.HEX;
      case 'BINARY':
        return SecretEncoding.BINARY;
      default:
        throw ArgumentError('Invalid SecretEncoding value: $value');
    }
  }
}

extension CardTypeX on CardType {
  String get value {
    switch (this) {
      case CardType.debit:
        return 'debit';
      case CardType.credit:
        return 'credit';
      case CardType.prepaid:
        return 'prepaid';
      case CardType.virtual:
        return 'virtual';
    }
  }

  static CardType fromString(String value) {
    switch (value) {
      case 'debit':
        return CardType.debit;
      case 'credit':
        return CardType.credit;
      case 'prepaid':
        return CardType.prepaid;
      case 'virtual':
        return CardType.virtual;
      default:
        throw ArgumentError('Invalid CardType value: $value');
    }
  }
}

extension CardNetworkX on CardNetwork {
  String get value {
    switch (this) {
      case CardNetwork.visa:
        return 'visa';
      case CardNetwork.mastercard:
        return 'mastercard';
      case CardNetwork.amex:
        return 'amex';
      case CardNetwork.discover:
        return 'discover';
      case CardNetwork.dinersclub:
        return 'dinersclub';
      case CardNetwork.jcb:
        return 'jcb';
      case CardNetwork.unionpay:
        return 'unionpay';
      case CardNetwork.other:
        return 'other';
    }
  }

  static CardNetwork fromString(String value) {
    switch (value) {
      case 'visa':
        return CardNetwork.visa;
      case 'mastercard':
        return CardNetwork.mastercard;
      case 'amex':
        return CardNetwork.amex;
      case 'discover':
        return CardNetwork.discover;
      case 'dinersclub':
        return CardNetwork.dinersclub;
      case 'jcb':
        return CardNetwork.jcb;
      case 'unionpay':
        return CardNetwork.unionpay;
      case 'other':
        return CardNetwork.other;
      default:
        throw ArgumentError('Invalid CardNetwork value: $value');
    }
  }
}
