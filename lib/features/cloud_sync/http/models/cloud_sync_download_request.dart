import 'dart:async';

import 'package:dio/dio.dart';

class CloudSyncDownloadRequest {
  const CloudSyncDownloadRequest({
    required this.url,
    this.method = 'GET',
    this.savePath,
    this.responseSink,
    this.headers,
    this.queryParameters,
    this.data,
    this.options,
    this.cancelToken,
    this.onReceiveProgress,
  });

  final String url;
  final String method;
  final String? savePath;
  final StreamConsumer<List<int>>? responseSink;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final Object? data;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onReceiveProgress;

  Uri get uri => Uri.parse(url);

  Options toOptions({Map<String, dynamic>? extra}) {
    final mergedHeaders = <String, dynamic>{...?options?.headers, ...?headers};
    final mergedExtra = <String, dynamic>{...?options?.extra, ...?extra};

    return (options ?? Options()).copyWith(
      method: method,
      responseType: ResponseType.stream,
      headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      extra: mergedExtra.isEmpty ? null : mergedExtra,
    );
  }
}
