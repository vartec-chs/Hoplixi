import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'crypto_wallets_filter.freezed.dart';
part 'crypto_wallets_filter.g.dart';

enum CryptoWalletsSortField {
  name,
  walletType,
  network,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class CryptoWalletsFilter with _$CryptoWalletsFilter {
  const factory CryptoWalletsFilter({
    required BaseFilter base,
    String? name,
    String? walletType,
    String? network,
    String? hardwareDevice,
    bool? watchOnly,
    bool? hasMnemonic,
    bool? hasPrivateKey,
    bool? hasXprv,
    CryptoWalletsSortField? sortField,
  }) = _CryptoWalletsFilter;

  factory CryptoWalletsFilter.create({
    BaseFilter? base,
    String? name,
    String? walletType,
    String? network,
    String? hardwareDevice,
    bool? watchOnly,
    bool? hasMnemonic,
    bool? hasPrivateKey,
    bool? hasXprv,
    CryptoWalletsSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return CryptoWalletsFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      walletType: normalize(walletType),
      network: normalize(network),
      hardwareDevice: normalize(hardwareDevice),
      watchOnly: watchOnly,
      hasMnemonic: hasMnemonic,
      hasPrivateKey: hasPrivateKey,
      hasXprv: hasXprv,
      sortField: sortField,
    );
  }

  factory CryptoWalletsFilter.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletsFilterFromJson(json);
}

extension CryptoWalletsFilterHelpers on CryptoWalletsFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (walletType != null) return true;
    if (network != null) return true;
    if (hardwareDevice != null) return true;
    if (watchOnly != null) return true;
    if (hasMnemonic != null) return true;
    if (hasPrivateKey != null) return true;
    if (hasXprv != null) return true;
    return false;
  }
}
