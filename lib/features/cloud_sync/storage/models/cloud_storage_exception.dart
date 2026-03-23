import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

enum CloudStorageExceptionType {
  unauthorized,
  notFound,
  alreadyExists,
  invalidReference,
  unsupportedOperation,
  quotaExceeded,
  rateLimited,
  network,
  timeout,
  cancelled,
  unknown,
}

class CloudStorageException implements Exception {
  const CloudStorageException({
    required this.type,
    required this.message,
    this.provider,
    this.statusCode,
    this.requestUri,
    this.responseBodySnippet,
    this.cause,
  });

  final CloudStorageExceptionType type;
  final String message;
  final CloudSyncProvider? provider;
  final int? statusCode;
  final Uri? requestUri;
  final String? responseBodySnippet;
  final Object? cause;

  @override
  String toString() {
    return 'CloudStorageException(type: $type, message: $message, provider: ${provider?.id}, statusCode: $statusCode, requestUri: $requestUri)';
  }
}
