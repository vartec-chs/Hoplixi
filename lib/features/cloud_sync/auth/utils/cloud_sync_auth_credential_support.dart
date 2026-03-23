import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_credential_option.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:universal_platform/universal_platform.dart';

bool get isCloudSyncMobilePlatform =>
    UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

bool get isCloudSyncDesktopPlatform => UniversalPlatform.isDesktop;

List<CloudSyncProvider> getSupportedAuthProviders() {
  return CloudSyncProvider.values
      .where((provider) => provider != CloudSyncProvider.other)
      .where((provider) => provider.metadata.supportsAuth)
      .toList(growable: false);
}

AuthCredentialOption buildAuthCredentialOption(AppCredentialEntry entry) {
  final metadata = entry.provider.metadata;

  if (!metadata.supportsAuth) {
    return AuthCredentialOption(
      entry: entry,
      isSupported: false,
      supportIssue: AuthCredentialSupportIssue.unsupportedProvider,
    );
  }

  if (isCloudSyncDesktopPlatform) {
    if (!metadata.supportsDesktopAuth || !entry.supportsDesktop) {
      return AuthCredentialOption(
        entry: entry,
        isSupported: false,
        supportIssue: AuthCredentialSupportIssue.mobilePlatformUnsupported,
      );
    }

    return AuthCredentialOption(entry: entry);
  }

  if (isCloudSyncMobilePlatform) {
    if (!metadata.supportsMobileAuth || !entry.supportsMobile) {
      return AuthCredentialOption(
        entry: entry,
        isSupported: false,
        supportIssue: AuthCredentialSupportIssue.mobilePlatformUnsupported,
      );
    }

    if (metadata.mobileRedirectPolicy ==
            CloudSyncMobileRedirectPolicy.dropboxClientScheme &&
        !entry.isBuiltin) {
      return AuthCredentialOption(
        entry: entry,
        isSupported: false,
        supportIssue: AuthCredentialSupportIssue.mobileDropboxRequiresBuiltin,
      );
    }
  }

  return AuthCredentialOption(entry: entry);
}

String? resolveCredentialRedirectUri(AppCredentialEntry entry) {
  final metadata = entry.provider.metadata;

  if (isCloudSyncDesktopPlatform) {
    return entry.supportsDesktop ? metadata.desktopRedirectUri : null;
  }

  if (!isCloudSyncMobilePlatform ||
      !metadata.supportsMobileAuth ||
      !entry.supportsMobile) {
    return null;
  }

  return switch (metadata.mobileRedirectPolicy) {
    CloudSyncMobileRedirectPolicy.genericAppScheme =>
      metadata.appCredentialsMobileRedirectUri,
    CloudSyncMobileRedirectPolicy.dropboxClientScheme =>
      entry.isBuiltin
          ? metadata.appCredentialsMobileRedirectUri.replaceAll(
              '<client_id>',
              entry.clientId,
            )
          : null,
  };
}
