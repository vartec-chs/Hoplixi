import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/ssh_key/ssh_key_items.dart';
import 'base_filter.dart';

part 'ssh_key_filter.freezed.dart';
part 'ssh_key_filter.g.dart';

enum SshKeySortField {
  name,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class SshKeyFilter with _$SshKeyFilter {
  const factory SshKeyFilter({
    @Default(BaseFilter()) BaseFilter base,

    SshKeyType? keyType,
    int? keySize,

    bool? hasPublicKey,
    bool? hasPrivateKey,

    SshKeySortField? sortField,
  }) = _SshKeyFilter;

  factory SshKeyFilter.create({
    BaseFilter? base,
    SshKeyType? keyType,
    int? keySize,
    bool? hasPublicKey,
    bool? hasPrivateKey,
    SshKeySortField? sortField,
  }) {
    return SshKeyFilter(
      base: base ?? const BaseFilter(),
      keyType: keyType,
      keySize: keySize,
      hasPublicKey: hasPublicKey,
      hasPrivateKey: hasPrivateKey,
      sortField: sortField,
    );
  }

  factory SshKeyFilter.fromJson(Map<String, dynamic> json) =>
      _$SshKeyFilterFromJson(json);
}

extension SshKeyFilterHelpers on SshKeyFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (keyType != null) return true;
    if (keySize != null) return true;
    if (hasPublicKey != null) return true;
    if (hasPrivateKey != null) return true;
    return false;
  }
}
