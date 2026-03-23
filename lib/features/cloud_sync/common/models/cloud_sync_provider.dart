import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Поддерживаемые провайдеры облачной синхронизации.
@JsonEnum(fieldRename: FieldRename.snake)
enum CloudSyncProvider { dropbox, google, onedrive, yandex, other }

@JsonEnum(fieldRename: FieldRename.snake)
enum CloudSyncMobileRedirectPolicy { genericAppScheme, dropboxClientScheme }

@JsonEnum(fieldRename: FieldRename.snake)
enum CloudSyncUserInfoMethod { get, post }

/// Статический конфиг провайдера для UI и OAuth-интеграции.
class CloudSyncProviderMetadata {
  const CloudSyncProviderMetadata({
    required this.displayName,
    required this.icon,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.supportsDesktopAuth,
    required this.supportsMobileAuth,
    required this.desktopRedirectUri,
    required this.mobileRedirectPolicy,
    required this.appCredentialsMobileRedirectUri,
    required this.authMobileRedirectHint,
    required this.scopes,
    this.userInfoEndpoint,
    this.userInfoMethod = CloudSyncUserInfoMethod.get,
    this.userInfoAuthScheme = 'Bearer',
    this.additionalAuthParameters = const <String, String>{},
  });

  final String displayName;
  final IconData icon;
  final String? authorizationEndpoint;
  final String? tokenEndpoint;
  final bool supportsDesktopAuth;
  final bool supportsMobileAuth;
  final String desktopRedirectUri;
  final CloudSyncMobileRedirectPolicy mobileRedirectPolicy;
  final String appCredentialsMobileRedirectUri;
  final String authMobileRedirectHint;
  final List<String> scopes;
  final String? userInfoEndpoint;
  final CloudSyncUserInfoMethod userInfoMethod;
  final String userInfoAuthScheme;
  final Map<String, String> additionalAuthParameters;

  bool get supportsAuth =>
      authorizationEndpoint != null &&
      tokenEndpoint != null &&
      (supportsDesktopAuth || supportsMobileAuth);
}

/// Метаданные провайдера для экранов cloud sync.
extension CloudSyncProviderX on CloudSyncProvider {
  String get id => name;

  CloudSyncProviderMetadata get metadata {
    return switch (this) {
      CloudSyncProvider.dropbox => const CloudSyncProviderMetadata(
        displayName: 'Dropbox',
        icon: Icons.cloud_circle_outlined,
        authorizationEndpoint: 'https://www.dropbox.com/oauth2/authorize',
        tokenEndpoint: 'https://api.dropboxapi.com/oauth2/token',
        supportsDesktopAuth: true,
        supportsMobileAuth: true,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        mobileRedirectPolicy: CloudSyncMobileRedirectPolicy.dropboxClientScheme,
        appCredentialsMobileRedirectUri: 'db-<client_id>://oauth2redirect',
        authMobileRedirectHint: 'db-<client_id>://oauth2redirect',
        scopes: [
          'account_info.read',
          'files.content.read',
          'files.content.write',
          'files.metadata.write',
          'files.metadata.read',
          'openid',
          'email',
          'profile',
        ],
        userInfoEndpoint:
            'https://api.dropboxapi.com/2/users/get_current_account',
        userInfoMethod: CloudSyncUserInfoMethod.post,
        additionalAuthParameters: {'token_access_type': 'offline'},
      ),
      CloudSyncProvider.google => const CloudSyncProviderMetadata(
        displayName: 'Google',
        icon: Icons.cloud_outlined,
        authorizationEndpoint: 'https://accounts.google.com/o/oauth2/auth',
        tokenEndpoint: 'https://oauth2.googleapis.com/token',
        supportsDesktopAuth: true,
        supportsMobileAuth: true,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        mobileRedirectPolicy: CloudSyncMobileRedirectPolicy.genericAppScheme,
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'hoplixiauth://oauth2redirect',
        scopes: [
          'https://www.googleapis.com/auth/drive.appdata',
          'https://www.googleapis.com/auth/drive.appfolder',
          'https://www.googleapis.com/auth/drive.install',
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.apps.readonly',
          'https://www.googleapis.com/auth/drive',
          'https://www.googleapis.com/auth/drive.readonly',
          'https://www.googleapis.com/auth/drive.activity',
          'https://www.googleapis.com/auth/drive.activity.readonly',
          'https://www.googleapis.com/auth/drive.meet.readonly',
          'https://www.googleapis.com/auth/drive.metadata',
          'https://www.googleapis.com/auth/drive.metadata.readonly',
          'https://www.googleapis.com/auth/drive.scripts',
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
        userInfoEndpoint: 'https://www.googleapis.com/oauth2/v2/userinfo',
        additionalAuthParameters: {
          'access_type': 'offline',
          'prompt': 'consent',
          'include_granted_scopes': 'true',
        },
      ),
      CloudSyncProvider.onedrive => const CloudSyncProviderMetadata(
        displayName: 'OneDrive',
        icon: Icons.cloud_done_outlined,
        authorizationEndpoint:
            'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
        tokenEndpoint:
            'https://login.microsoftonline.com/common/oauth2/v2.0/token',
        supportsDesktopAuth: true,
        supportsMobileAuth: true,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        mobileRedirectPolicy: CloudSyncMobileRedirectPolicy.genericAppScheme,
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'hoplixiauth://oauth2redirect',
        scopes: [
          'User.Read',
          'User.ReadBasic.All',
          'email',
          'openid',
          'profile',
          'Files.Read',
          'Files.Read.All',
          'Files.ReadWrite',
          'Files.ReadWrite.All',
          'Files.ReadWrite.AppFolder',
          'Files.SelectedOperations.Selected',
          'offline_access',
        ],
        userInfoEndpoint: 'https://graph.microsoft.com/v1.0/me',
      ),
      CloudSyncProvider.yandex => const CloudSyncProviderMetadata(
        displayName: 'Yandex',
        icon: Icons.language,
        authorizationEndpoint: 'https://oauth.yandex.ru/authorize',
        tokenEndpoint: 'https://oauth.yandex.ru/token',
        supportsDesktopAuth: true,
        supportsMobileAuth: true,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        mobileRedirectPolicy: CloudSyncMobileRedirectPolicy.genericAppScheme,
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'hoplixiauth://oauth2redirect',
        scopes: [
          'login:info',
          'login:email',
          'cloud_api:disk.write',
          'cloud_api:disk.read',
          'cloud_api:disk.app_folder',
          'cloud_api:disk.info',
        ],
        userInfoEndpoint: 'https://login.yandex.ru/info',
        userInfoAuthScheme: 'OAuth',
      ),
      CloudSyncProvider.other => const CloudSyncProviderMetadata(
        displayName: 'Other',
        icon: Icons.extension_outlined,
        authorizationEndpoint: null,
        tokenEndpoint: null,
        supportsDesktopAuth: false,
        supportsMobileAuth: false,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        mobileRedirectPolicy: CloudSyncMobileRedirectPolicy.genericAppScheme,
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'hoplixiauth://oauth2redirect',
        scopes: [],
      ),
    };
  }
}
