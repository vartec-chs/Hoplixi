import 'package:freezed_annotation/freezed_annotation.dart';

part 'oauth_apps.freezed.dart';
part 'oauth_apps.g.dart';

enum OauthAppsType { google, onedrive, dropbox, yandex, other }

extension OauthAppsTypeX on OauthAppsType {
  String get name {
    switch (this) {
      case OauthAppsType.google:
        return 'Google';
      case OauthAppsType.onedrive:
        return 'OneDrive';
      case OauthAppsType.dropbox:
        return 'Dropbox';
      case OauthAppsType.yandex:
        return 'Yandex';
      case OauthAppsType.other:
        return 'Other';
    }
  }

  String get identifier {
    switch (this) {
      case OauthAppsType.google:
        return 'google';
      case OauthAppsType.onedrive:
        return 'onedrive';
      case OauthAppsType.dropbox:
        return 'dropbox';
      case OauthAppsType.yandex:
        return 'yandex';
      case OauthAppsType.other:
        return 'other';
    }
  }

  static OauthAppsType fromIdentifier(String identifier) {
    switch (identifier) {
      case 'google':
        return OauthAppsType.google;
      case 'onedrive':
        return OauthAppsType.onedrive;
      case 'dropbox':
        return OauthAppsType.dropbox;
      case 'yandex':
        return OauthAppsType.yandex;
      default:
        return OauthAppsType.other;
    }
  }

  // is active
  bool get isActive {
    switch (this) {
      case OauthAppsType.google:
        return true;
      case OauthAppsType.onedrive:
        return true;
      case OauthAppsType.dropbox:
        return true;
      case OauthAppsType.yandex:
        return true;
      case OauthAppsType.other:
        return false;
    }
  }
}

@freezed
sealed class OauthApps with _$OauthApps {
  const factory OauthApps({
    required String id,
    required String name,
    required OauthAppsType type,
    required String clientId,
    String? clientSecret,
    @Default(false) bool isBuiltin,
  }) = _OauthApps;

  factory OauthApps.fromJson(Map<String, dynamic> json) =>
      _$OauthAppsFromJson(json);
}
