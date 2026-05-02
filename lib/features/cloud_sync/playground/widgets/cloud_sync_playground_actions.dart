import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/routing/paths.dart';

String cloudSyncStorageRouteFor(CloudSyncProvider provider) {
  return AppRoutesPaths.cloudSyncStorageForProvider(provider.id);
}

Future<void> openCloudSyncAuthSheet(BuildContext context) async {
  await showCloudSyncAuthSheet(
    context: context,
    container: ProviderScope.containerOf(context, listen: false),
    previousRoute: AppRoutesPaths.cloudSync,
  );
}

void openCloudSyncCredentials(BuildContext context) {
  context.push(AppRoutesPaths.cloudSyncAppCredentials);
}

void openCloudSyncTokens(BuildContext context) {
  context.push(AppRoutesPaths.cloudSyncAuthTokens);
}

void openCloudSyncStorage(BuildContext context) {
  context.push(AppRoutesPaths.cloudSyncStorage);
}

void openCloudSyncStorageForProvider(
  BuildContext context,
  CloudSyncProvider provider,
) {
  context.push(cloudSyncStorageRouteFor(provider));
}
