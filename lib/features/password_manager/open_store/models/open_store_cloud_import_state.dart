import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';

const _cloudStateSentinel = Object();

class OpenStoreCloudImportState {
  final Map<CloudSyncProvider, List<AuthTokenEntry>> cloudTokensByProvider;
  final CloudSyncProvider? selectedCloudProvider;
  final String? selectedCloudTokenId;
  final List<CloudManifestStoreEntry> remoteSnapshots;
  final bool isLoadingRemoteSnapshots;
  final String? remoteSnapshotsError;
  final String? downloadingRemoteStoreUuid;
  final PendingImportedStoreBinding? pendingImportedStoreBinding;

  const OpenStoreCloudImportState({
    this.cloudTokensByProvider =
        const <CloudSyncProvider, List<AuthTokenEntry>>{},
    this.selectedCloudProvider,
    this.selectedCloudTokenId,
    this.remoteSnapshots = const <CloudManifestStoreEntry>[],
    this.isLoadingRemoteSnapshots = false,
    this.remoteSnapshotsError,
    this.downloadingRemoteStoreUuid,
    this.pendingImportedStoreBinding,
  });

  OpenStoreCloudImportState copyWith({
    Map<CloudSyncProvider, List<AuthTokenEntry>>? cloudTokensByProvider,
    Object? selectedCloudProvider = _cloudStateSentinel,
    Object? selectedCloudTokenId = _cloudStateSentinel,
    List<CloudManifestStoreEntry>? remoteSnapshots,
    bool? isLoadingRemoteSnapshots,
    Object? remoteSnapshotsError = _cloudStateSentinel,
    Object? downloadingRemoteStoreUuid = _cloudStateSentinel,
    Object? pendingImportedStoreBinding = _cloudStateSentinel,
  }) {
    return OpenStoreCloudImportState(
      cloudTokensByProvider:
          cloudTokensByProvider ?? this.cloudTokensByProvider,
      selectedCloudProvider:
          identical(selectedCloudProvider, _cloudStateSentinel)
          ? this.selectedCloudProvider
          : selectedCloudProvider as CloudSyncProvider?,
      selectedCloudTokenId: identical(selectedCloudTokenId, _cloudStateSentinel)
          ? this.selectedCloudTokenId
          : selectedCloudTokenId as String?,
      remoteSnapshots: remoteSnapshots ?? this.remoteSnapshots,
      isLoadingRemoteSnapshots:
          isLoadingRemoteSnapshots ?? this.isLoadingRemoteSnapshots,
      remoteSnapshotsError: identical(remoteSnapshotsError, _cloudStateSentinel)
          ? this.remoteSnapshotsError
          : remoteSnapshotsError as String?,
      downloadingRemoteStoreUuid:
          identical(downloadingRemoteStoreUuid, _cloudStateSentinel)
          ? this.downloadingRemoteStoreUuid
          : downloadingRemoteStoreUuid as String?,
      pendingImportedStoreBinding:
          identical(pendingImportedStoreBinding, _cloudStateSentinel)
          ? this.pendingImportedStoreBinding
          : pendingImportedStoreBinding as PendingImportedStoreBinding?,
    );
  }
}
