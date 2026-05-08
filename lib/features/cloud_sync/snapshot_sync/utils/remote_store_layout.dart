import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';

class RemoteStoreLayout {
  const RemoteStoreLayout({
    required this.rootFolder,
    required this.storesFolder,
    required this.storeFolder,
    required this.attachmentsFolder,
  });

  final CloudResource rootFolder;
  final CloudResource storesFolder;
  final CloudResource storeFolder;
  final CloudResource attachmentsFolder;
}
