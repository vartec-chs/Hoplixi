import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'passwords_filter.freezed.dart';
part 'passwords_filter.g.dart';

enum PasswordsSortField {
  name,
  login,
  email,
  url,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class PasswordsFilter with _$PasswordsFilter {
  const factory PasswordsFilter({
    required BaseFilter base,
    String? name,
    String? login,
    String? email,
    String? url,
    bool? hasDescription,
    bool? hasNotes,
    bool? hasUrl,
    bool? hasLogin,
    bool? hasEmail,
    PasswordsSortField? sortField,
  }) = _PasswordsFilter;

  factory PasswordsFilter.create({
    BaseFilter? base,
    String? name,
    String? login,
    String? email,
    String? url,
    bool? hasDescription,
    bool? hasNotes,
    bool? hasUrl,
    bool? hasLogin,
    bool? hasEmail,
    PasswordsSortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedLogin = login?.trim();
    final normalizedEmail = email?.trim();
    final normalizedUrl = url?.trim();

    return PasswordsFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      login: normalizedLogin?.isEmpty == true ? null : normalizedLogin,
      email: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      url: normalizedUrl?.isEmpty == true ? null : normalizedUrl,
      hasDescription: hasDescription,
      hasNotes: hasNotes,
      hasUrl: hasUrl,
      hasLogin: hasLogin,
      hasEmail: hasEmail,
      sortField: sortField,
    );
  }

  factory PasswordsFilter.fromJson(Map<String, dynamic> json) =>
      _$PasswordsFilterFromJson(json);
}

extension PasswordsFilterHelpers on PasswordsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (login != null) return true;
    if (email != null) return true;
    if (url != null) return true;
    if (hasDescription != null) return true;
    if (hasNotes != null) return true;
    if (hasUrl != null) return true;
    if (hasLogin != null) return true;
    if (hasEmail != null) return true;
    return false;
  }

  /// Проверка валидности email (базовая)
  bool get isValidEmail {
    if (email == null || email!.isEmpty) return true;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email!);
  }

  /// Проверка валидности URL (базовая)
  bool get isValidUrl {
    if (url == null || url!.isEmpty) return true;
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(url!);
  }

  /// Есть ли хотя бы одно из средств идентификации (login или email)
  bool get hasLoginOrEmail => hasLogin == true || hasEmail == true;
}
