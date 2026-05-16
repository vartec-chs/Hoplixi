import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import 'base_filter.dart';

part 'crypto_wallet_filter.freezed.dart';
part 'crypto_wallet_filter.g.dart';

enum CryptoWalletSortField {
  name,
  walletType,
  network,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class CryptoWalletFilter with _$CryptoWalletFilter {
  const factory CryptoWalletFilter({
    @Default(BaseFilter()) BaseFilter base,

    CryptoWalletType? walletType,
    CryptoNetwork? network,
    CryptoDerivationScheme? derivationScheme,
    bool? watchOnly,

    bool? hasMnemonic,
    bool? hasPrivateKey,
    bool? hasXpub,
    bool? hasXprv,
    String? hardwareDevice,

    CryptoWalletSortField? sortField,
  }) = _CryptoWalletFilter;

  factory CryptoWalletFilter.create({
    BaseFilter? base,
    CryptoWalletType? walletType,
    CryptoNetwork? network,
    CryptoDerivationScheme? derivationScheme,
    bool? watchOnly,
    bool? hasMnemonic,
    bool? hasPrivateKey,
    bool? hasXpub,
    bool? hasXprv,
    String? hardwareDevice,
    CryptoWalletSortField? sortField,
  }) {
    final normalizedDevice = hardwareDevice?.trim();

    return CryptoWalletFilter(
      base: base ?? const BaseFilter(),
      walletType: walletType,
      network: network,
      derivationScheme: derivationScheme,
      watchOnly: watchOnly,
      hasMnemonic: hasMnemonic,
      hasPrivateKey: hasPrivateKey,
      hasXpub: hasXpub,
      hasXprv: hasXprv,
      hardwareDevice: normalizedDevice?.isEmpty == true ? null : normalizedDevice,
      sortField: sortField,
    );
  }

  factory CryptoWalletFilter.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletFilterFromJson(json);
}

extension CryptoWalletFilterHelpers on CryptoWalletFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (walletType != null) return true;
    if (network != null) return true;
    if (derivationScheme != null) return true;
    if (watchOnly != null) return true;
    if (hasMnemonic != null) return true;
    if (hasPrivateKey != null) return true;
    if (hasXpub != null) return true;
    if (hasXprv != null) return true;
    if (hardwareDevice != null) return true;
    return false;
  }
}
