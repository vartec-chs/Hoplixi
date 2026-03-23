import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_metadata.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';

class CloudResource {
  const CloudResource({
    required this.ref,
    required this.provider,
    required this.kind,
    required this.name,
    this.parentRef,
    this.metadata = const CloudResourceMetadata(),
  });

  final CloudResourceRef ref;
  final CloudSyncProvider provider;
  final CloudResourceKind kind;
  final String name;
  final CloudResourceRef? parentRef;
  final CloudResourceMetadata metadata;

  bool get isFile => kind == CloudResourceKind.file;

  bool get isFolder => kind == CloudResourceKind.folder;
}
