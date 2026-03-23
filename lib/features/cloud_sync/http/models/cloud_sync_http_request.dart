import 'package:dio/dio.dart';

class CloudSyncHttpRequest {
  const CloudSyncHttpRequest({
    required this.method,
    required this.url,
    this.headers,
    this.queryParameters,
    this.data,
    this.options,
    this.cancelToken,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final Object? data;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onSendProgress;
  final ProgressCallback? onReceiveProgress;

  Uri get uri => Uri.parse(url);

  Options toOptions({ResponseType? responseType, Map<String, dynamic>? extra}) {
    final mergedHeaders = <String, dynamic>{...?options?.headers, ...?headers};
    final mergedExtra = <String, dynamic>{...?options?.extra, ...?extra};

    return (options ?? Options()).copyWith(
      method: method,
      headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      responseType: responseType ?? options?.responseType,
      extra: mergedExtra.isEmpty ? null : mergedExtra,
    );
  }
}
