import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/old/models/enums/index.dart';
import 'base_filter.dart';

part 'otps_filter.freezed.dart';
part 'otps_filter.g.dart';

enum OtpsSortField {
  issuer,
  accountName,
  type,
  algorithm,
  digits,
  period,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class OtpsFilter with _$OtpsFilter {
  const factory OtpsFilter({
    required BaseFilter base,
    @Default(<OtpType>[]) List<OtpType> types,
    @Default(<AlgorithmOtp>[]) List<AlgorithmOtp> algorithms,
    String? issuer,
    String? accountName,
    @Default(<int>[]) List<int> digits,
    @Default(<int>[]) List<int> periods,
    @Default(<SecretEncoding>[]) List<SecretEncoding> secretEncodings,
    bool? hasPasswordLink,
    bool? hasNotes,
    OtpsSortField? sortField,
  }) = _OtpsFilter;

  factory OtpsFilter.create({
    BaseFilter? base,
    List<OtpType>? types,
    List<AlgorithmOtp>? algorithms,
    String? issuer,
    String? accountName,
    List<int>? digits,
    List<int>? periods,
    List<SecretEncoding>? secretEncodings,
    bool? hasPasswordLink,
    bool? hasNotes,
    OtpsSortField? sortField,
  }) {
    final normalizedIssuer = issuer?.trim();
    final normalizedAccountName = accountName?.trim();
    final normalizedTypes = (types ?? <OtpType>[]).toSet().toList();
    final normalizedAlgorithms = (algorithms ?? <AlgorithmOtp>[])
        .toSet()
        .toList();
    final normalizedDigits = (digits ?? <int>[]).toSet().toList();
    final normalizedPeriods = (periods ?? <int>[]).toSet().toList();
    final normalizedSecretEncodings = (secretEncodings ?? <SecretEncoding>[])
        .toSet()
        .toList();

    return OtpsFilter(
      base: base ?? const BaseFilter(),
      types: normalizedTypes,
      algorithms: normalizedAlgorithms,
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
      accountName: normalizedAccountName?.isEmpty == true
          ? null
          : normalizedAccountName,
      digits: normalizedDigits,
      periods: normalizedPeriods,
      secretEncodings: normalizedSecretEncodings,
      hasPasswordLink: hasPasswordLink,
      hasNotes: hasNotes,
      sortField: sortField,
    );
  }

  factory OtpsFilter.fromJson(Map<String, dynamic> json) =>
      _$OtpsFilterFromJson(json);
}

extension OtpsFilterHelpers on OtpsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (types.isNotEmpty) return true;
    if (algorithms.isNotEmpty) return true;
    if (issuer != null) return true;
    if (accountName != null) return true;
    if (digits.isNotEmpty) return true;
    if (periods.isNotEmpty) return true;
    if (secretEncodings.isNotEmpty) return true;
    if (hasPasswordLink != null) return true;
    if (hasNotes != null) return true;
    return false;
  }

  /// Проверка валидности периода для TOTP
  bool get isValidPeriod {
    for (final period in periods) {
      if (period <= 0 || period > 300) {
        // от 1 секунды до 5 минут
        return false;
      }
    }
    return true;
  }

  /// Проверка валидности количества цифр
  bool get isValidDigits {
    for (final digit in digits) {
      if (digit != 6 && digit != 8) {
        // стандартные значения
        return false;
      }
    }
    return true;
  }

  /// Фильтр только для TOTP
  bool get isTotpOnly => types.length == 1 && types.first == OtpType.totp;

  /// Фильтр только для HOTP
  bool get isHotpOnly => types.length == 1 && types.first == OtpType.hotp;
}
