import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_download_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_upload_request.dart';

abstract interface class CloudSyncHttpTransport {
  Future<Response<T>> request<T>(CloudSyncHttpRequest request);

  Future<ResponseBody> download(CloudSyncDownloadRequest request);

  Future<Response<T>> upload<T>(CloudSyncUploadRequest request);

  void close({bool force = true});
}
