import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';


final List<AppCredentialEntry> builtinAppCredentials = [
  _buildBuiltinCredential(
    id: 'builtin_dropbox_hoplixi',
    provider: CloudSyncProvider.dropbox,
    envPrefix: 'DROPBOX',
  ),
  _buildBuiltinCredential(
    id: 'builtin_google_hoplixi',
    provider: CloudSyncProvider.google,
    envPrefix: 'GOOGLE',
  ),
  _buildBuiltinCredential(
    id: 'builtin_yandex_hoplixi',
    provider: CloudSyncProvider.yandex,
    envPrefix: 'YANDEX',
  ),
  _buildBuiltinCredential(
    id: 'builtin_onedrive_hoplixi',
    provider: CloudSyncProvider.onedrive,
    envPrefix: 'ONEDRIVE',
  ),
].whereType<AppCredentialEntry>().toList(growable: false);

AppCredentialEntry? _buildBuiltinCredential({
  required String id,
  required CloudSyncProvider provider,
  required String envPrefix,
}) {
  if (dotenv.env['USED_BUILTIN_AUTH_APPS']?.toLowerCase() != 'true') {
    return null;
  }

  if (dotenv.env['${envPrefix}_BUILTIN_ENABLED']?.toLowerCase() != 'true') {
    return null;
  }

  final name = dotenv.env['${envPrefix}_APP_NAME']?.trim();
  final clientId = dotenv.env['${envPrefix}_CLIENT_ID']?.trim();
  final clientSecret = dotenv.env['${envPrefix}_CLIENT_SECRET']?.trim();

  if (name == null || name.isEmpty || clientId == null || clientId.isEmpty) {
    return null;
  }

  return AppCredentialEntry(
    id: id,
    provider: provider,
    name: name,
    clientId: clientId,
    clientSecret: clientSecret == null || clientSecret.isEmpty
        ? null
        : clientSecret,
    isBuiltin: true,
  );
}
