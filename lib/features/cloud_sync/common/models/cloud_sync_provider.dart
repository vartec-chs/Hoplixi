import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Поддерживаемые провайдеры облачной синхронизации.
@JsonEnum(fieldRename: FieldRename.snake)
enum CloudSyncProvider { dropbox, google, onedrive, yandex, other }

/// Статический конфиг провайдера для UI и будущей OAuth-интеграции.
class CloudSyncProviderMetadata {
  const CloudSyncProviderMetadata({
    required this.displayName,
    required this.icon,
    required this.desktopRedirectUri,
    required this.appCredentialsMobileRedirectUri,
    required this.authMobileRedirectHint,
    required this.scopes,
  });

  final String displayName;
  final IconData icon;
  final String desktopRedirectUri;
  final String appCredentialsMobileRedirectUri;
  final String authMobileRedirectHint;
  final List<String> scopes;
}

/// Метаданные провайдера для экранов cloud sync.
extension CloudSyncProviderX on CloudSyncProvider {
  String get id => name;

  CloudSyncProviderMetadata get metadata {
    return switch (this) {
      CloudSyncProvider.dropbox => const CloudSyncProviderMetadata(
        displayName: 'Dropbox',
        icon: Icons.cloud_circle_outlined,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
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
      ),
      CloudSyncProvider.google => const CloudSyncProviderMetadata(
        displayName: 'Google',
        icon: Icons.cloud_outlined,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
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
      ),
      CloudSyncProvider.onedrive => const CloudSyncProviderMetadata(
        displayName: 'OneDrive',
        icon: Icons.cloud_done_outlined,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'msauth://<package>/<signature_hash>',
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
      ),
      CloudSyncProvider.yandex => const CloudSyncProviderMetadata(
        displayName: 'Yandex',
        icon: Icons.language,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
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
      ),
      CloudSyncProvider.other => const CloudSyncProviderMetadata(
        displayName: 'Other',
        icon: Icons.extension_outlined,
        desktopRedirectUri: 'http://127.0.0.1:8569/callback',
        appCredentialsMobileRedirectUri: 'hoplixiauth://oauth2redirect',
        authMobileRedirectHint: 'hoplixiauth://oauth2redirect',
        scopes: [],
      ),
    };
  }
}
