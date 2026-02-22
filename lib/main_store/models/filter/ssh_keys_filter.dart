import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'ssh_keys_filter.freezed.dart';
part 'ssh_keys_filter.g.dart';

enum SshKeysSortField {
  name,
  keyType,
  fingerprint,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class SshKeysFilter with _$SshKeysFilter {
  const factory SshKeysFilter({
    required BaseFilter base,
    String? name,
    String? publicKey,
    String? keyType,
    String? fingerprint,
    String? createdBy,
    String? usage,
    bool? addedToAgent,
    bool? hasFileRefs,
    SshKeysSortField? sortField,
  }) = _SshKeysFilter;

  factory SshKeysFilter.create({
    BaseFilter? base,
    String? name,
    String? publicKey,
    String? keyType,
    String? fingerprint,
    String? createdBy,
    String? usage,
    bool? addedToAgent,
    bool? hasFileRefs,
    SshKeysSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return SshKeysFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      publicKey: normalize(publicKey),
      keyType: normalize(keyType),
      fingerprint: normalize(fingerprint),
      createdBy: normalize(createdBy),
      usage: normalize(usage),
      addedToAgent: addedToAgent,
      hasFileRefs: hasFileRefs,
      sortField: sortField,
    );
  }

  factory SshKeysFilter.fromJson(Map<String, dynamic> json) =>
      _$SshKeysFilterFromJson(json);
}

extension SshKeysFilterHelpers on SshKeysFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (publicKey != null) return true;
    if (keyType != null) return true;
    if (fingerprint != null) return true;
    if (createdBy != null) return true;
    if (usage != null) return true;
    if (addedToAgent != null) return true;
    if (hasFileRefs != null) return true;
    return false;
  }
}
