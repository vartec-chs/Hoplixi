import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';

class CloudFolder {
  CloudFolder(this.resource)
    : assert(
        resource.kind == CloudResourceKind.folder,
        'CloudFolder requires a folder resource.',
      );

  final CloudResource resource;
}
