class OAuthConfig {
  static const String redirectUri = 'http://localhost:8569/callback';
  static const String redirectUriMobile = 'hoplixiauth://callback';

  static const List<String> googleScopes = [
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
  ];

  static const List<String> onedriveScopes = [
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
  ];

  static const List<String> dropboxScopes = [
    "account_info.read",
    "files.content.read",
    "files.content.write",
    "files.metadata.write",
    "files.metadata.read",
    'openid',
    'email',
    "profile",
  ];

  static const List<String> yandexScopes = [
    'login:info',
    'login:email',
    'cloud_api:disk.write',
    'cloud_api:disk.read',
    'cloud_api:disk.app_folder',
    'cloud_api:disk.info',
  ];
}
