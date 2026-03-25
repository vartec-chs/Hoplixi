import 'package:dio/dio.dart';

class CloudSyncUploadRequest {
  const CloudSyncUploadRequest({
    required this.url,
    this.method = 'POST',
    this.headers,
    this.queryParameters,
    this.data,
    this.options,
    this.cancelToken,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  final String url;
  final String method;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final Object? data;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onSendProgress;
  final ProgressCallback? onReceiveProgress;

  Uri get uri {
    final baseUri = Uri.parse(url);
    if (queryParameters == null || queryParameters!.isEmpty) {
      return baseUri;
    }

    final mergedQuery = <String, String>{
      ...baseUri.queryParameters,
      ...queryParameters!.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    };

    return baseUri.replace(queryParameters: mergedQuery);
  }

  Options toOptions({Map<String, dynamic>? extra}) {
    final mergedHeaders = <String, dynamic>{...?options?.headers, ...?headers};
    final mergedExtra = <String, dynamic>{...?options?.extra, ...?extra};

    return (options ?? Options()).copyWith(
      method: method,
      headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      contentType: options?.contentType,
      responseType: options?.responseType,
      sendTimeout: options?.sendTimeout,
      receiveTimeout: options?.receiveTimeout,
      connectTimeout: options?.connectTimeout,
      followRedirects: options?.followRedirects,
      receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
      validateStatus: options?.validateStatus,
      persistentConnection: options?.persistentConnection,
      listFormat: options?.listFormat,
      extra: mergedExtra.isEmpty ? null : mergedExtra,
    );
  }
}
