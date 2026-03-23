import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';

class CloudListPage {
  const CloudListPage({this.items = const <CloudResource>[], this.nextCursor});

  final List<CloudResource> items;
  final String? nextCursor;
}
