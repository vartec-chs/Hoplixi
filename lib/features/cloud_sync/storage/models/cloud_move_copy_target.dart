import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';

class CloudMoveCopyTarget {
  const CloudMoveCopyTarget({required this.parentRef, required this.name});

  final CloudResourceRef parentRef;
  final String name;
}
