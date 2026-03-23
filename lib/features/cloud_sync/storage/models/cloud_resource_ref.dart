import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudResourceRef {
  const CloudResourceRef({
    required this.provider,
    this.resourceId,
    this.path,
    this.isRoot = false,
  });

  const CloudResourceRef.root({
    required CloudSyncProvider provider,
    String? resourceId,
    String? path,
  }) : this(
         provider: provider,
         resourceId: resourceId,
         path: path,
         isRoot: true,
       );

  final CloudSyncProvider provider;
  final String? resourceId;
  final String? path;
  final bool isRoot;

  bool get hasAddress =>
      isRoot ||
      (resourceId != null && resourceId!.trim().isNotEmpty) ||
      (path != null && path!.trim().isNotEmpty);

  CloudResourceRef copyWith({
    CloudSyncProvider? provider,
    String? resourceId,
    String? path,
    bool? isRoot,
  }) {
    return CloudResourceRef(
      provider: provider ?? this.provider,
      resourceId: resourceId ?? this.resourceId,
      path: path ?? this.path,
      isRoot: isRoot ?? this.isRoot,
    );
  }

  @override
  String toString() {
    return 'CloudResourceRef(provider: ${provider.id}, resourceId: $resourceId, path: $path, isRoot: $isRoot)';
  }
}
