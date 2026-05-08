import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';

class CloudVersionCheckData {
  const CloudVersionCheckData({
    required this.manifest,
    required this.binding,
    required this.token,
  });

  final StoreManifest manifest;
  final StoreSyncBinding binding;
  final AuthTokenEntry token;
}
