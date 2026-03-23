import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';

class CloudSyncAuthException implements Exception {
  const CloudSyncAuthException(this.error);

  final CloudSyncAuthError error;

  @override
  String toString() => 'CloudSyncAuthException(error: $error)';
}
