import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';

class CloudFile {
  CloudFile(this.resource)
    : assert(
        resource.kind == CloudResourceKind.file,
        'CloudFile requires a file resource.',
      );

  final CloudResource resource;
}
