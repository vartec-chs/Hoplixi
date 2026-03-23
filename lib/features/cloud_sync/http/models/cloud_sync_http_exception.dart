import 'dart:convert';

import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

enum CloudSyncHttpExceptionType {
  unauthorized,
  refreshFailed,
  network,
  timeout,
  cancelled,
  badResponse,
  misconfiguredProvider,
  tokenNotFound,
  unknown,
}

class CloudSyncHttpException implements Exception {
  const CloudSyncHttpException({
    required this.type,
    required this.message,
    this.provider,
    this.tokenId,
    this.statusCode,
    this.requestUri,
    this.responseBodySnippet,
    this.cause,
  });

  final CloudSyncHttpExceptionType type;
  final String message;
  final CloudSyncProvider? provider;
  final String? tokenId;
  final int? statusCode;
  final Uri? requestUri;
  final String? responseBodySnippet;
  final Object? cause;

  bool get isUnauthorized =>
      type == CloudSyncHttpExceptionType.unauthorized ||
      type == CloudSyncHttpExceptionType.refreshFailed;

  @override
  String toString() {
    final buffer = StringBuffer('CloudSyncHttpException($type, $message');
    if (provider != null) {
      buffer.write(', provider: ${provider!.id}');
    }
    if (tokenId != null) {
      buffer.write(', tokenId: $tokenId');
    }
    if (statusCode != null) {
      buffer.write(', statusCode: $statusCode');
    }
    if (requestUri != null) {
      buffer.write(', requestUri: $requestUri');
    }
    if (responseBodySnippet != null && responseBodySnippet!.isNotEmpty) {
      buffer.write(', response: $responseBodySnippet');
    }
    buffer.write(')');
    return buffer.toString();
  }

  static String? buildResponseBodySnippet(Object? data, {int maxLength = 400}) {
    if (data == null) {
      return null;
    }

    String raw;
    if (data is String) {
      raw = data;
    } else {
      try {
        raw = jsonEncode(data);
      } catch (_) {
        raw = data.toString();
      }
    }

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength)}...';
  }
}
