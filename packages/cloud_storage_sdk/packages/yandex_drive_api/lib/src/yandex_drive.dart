import 'package:oauth2restclient/oauth2restclient.dart';

import 'models/disk_info.dart';
import 'interface.dart';
import 'models/link.dart';
import 'models/resource.dart';
import 'models/resource_list.dart';

class YandexDrive implements YandexDriveApi {
  final OAuth2RestClient client;
  final String _baseUrl = 'https://cloud-api.yandex.net/v1/disk';

  YandexDrive(this.client);

  Map<String, String> _makeQueryParams({
    String? path,
    List<String>? fields,
    int? limit,
    int? offset,
    String? previewSize,
    bool? previewCrop,
    String? sort,
    String? mediaType,
    bool? overwrite,
    bool? permanently,
    String? publicKey,
    String? name,
    bool? disableRedirects,
    String? url,
  }) {
    final Map<String, String> queryParams = {};

    if (path != null) queryParams['path'] = path;
    if (fields != null) queryParams['fields'] = fields.join(',');
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (previewSize != null) queryParams['preview_size'] = previewSize;
    if (previewCrop != null) {
      queryParams['preview_crop'] = previewCrop.toString();
    }
    if (sort != null) queryParams['sort'] = sort;
    if (mediaType != null) queryParams['media_type'] = mediaType;
    if (overwrite != null) queryParams['overwrite'] = overwrite.toString();
    if (permanently != null) {
      queryParams['permanently'] = permanently.toString();
    }
    if (publicKey != null) queryParams['public_key'] = publicKey;
    if (name != null) queryParams['name'] = name;
    if (disableRedirects != null) {
      queryParams['disable_redirects'] = disableRedirects.toString();
    }
    if (url != null) queryParams['url'] = url;

    return queryParams;
  }

  @override
  Future<DiskInfo> getDiskInfo() async {
    final json = await client.getJson('$_baseUrl/');
    return DiskInfo.fromJson(json);
  }

  @override
  Future<Resource> getResource(
    String path, {
    List<String>? fields,
    int? limit,
    int? offset,
    String? previewSize,
    bool? previewCrop,
    String? sort,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      fields: fields,
      limit: limit,
      offset: offset,
      previewSize: previewSize,
      previewCrop: previewCrop,
      sort: sort,
    );
    final json = await client.getJson(
      '$_baseUrl/resources',
      queryParams: queryParams,
    );
    return Resource.fromJson(json);
  }

  @override
  Future<Resource> updateResource(
    String path, {
    Map<String, dynamic>? customProperties,
    List<String>? fields,
  }) async {
    final queryParams = _makeQueryParams(path: path, fields: fields);
    final body = customProperties != null
        ? OAuth2JsonBody({'custom_properties': customProperties})
        : null;

    final json = await client.patchJson(
      '$_baseUrl/resources',
      queryParams: queryParams,
      body: body,
    );
    return Resource.fromJson(json);
  }

  @override
  Future<ResourceList> getFiles({
    int? limit,
    String? mediaType,
    int? offset,
    List<String>? fields,
    String? previewSize,
    bool? previewCrop,
  }) async {
    final queryParams = _makeQueryParams(
      limit: limit,
      mediaType: mediaType,
      offset: offset,
      fields: fields,
      previewSize: previewSize,
      previewCrop: previewCrop,
    );
    final json = await client.getJson(
      '$_baseUrl/resources/files',
      queryParams: queryParams,
    );
    return ResourceList.fromJson(json);
  }

  @override
  Future<ResourceList> getLastUploadedFiles({
    int? limit,
    String? mediaType,
    List<String>? fields,
    String? previewSize,
    bool? previewCrop,
  }) async {
    final queryParams = _makeQueryParams(
      limit: limit,
      mediaType: mediaType,
      fields: fields,
      previewSize: previewSize,
      previewCrop: previewCrop,
    );
    final json = await client.getJson(
      '$_baseUrl/resources/last-uploaded',
      queryParams: queryParams,
    );
    return ResourceList.fromJson(json);
  }

  @override
  Future<Link> getUploadLink(
    String path, {
    bool? overwrite,
    List<String>? fields,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      overwrite: overwrite,
      fields: fields,
    );
    final json = await client.getJson(
      '$_baseUrl/resources/upload',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> uploadFileFromUrl(
    String url,
    String path, {
    List<String>? fields,
    bool? disableRedirects,
    OAuth2ProgressCallback? onProgress,
  }) async {
    final queryParams = _makeQueryParams(
      url: url,
      path: path,
      fields: fields,
      disableRedirects: disableRedirects,
    );
    final json = await client.postJson(
      '$_baseUrl/resources/upload',
      queryParams: queryParams,
      onProgress: onProgress,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> getDownloadLink(String path, {List<String>? fields}) async {
    final queryParams = _makeQueryParams(path: path, fields: fields);
    final json = await client.getJson(
      '$_baseUrl/resources/download',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<void> uploadFile(
    String path,
    Stream<List<int>> fileStream,
    int contentLength, {
    bool? overwrite,
    OAuth2ProgressCallback? onProgress,
  }) async {
    final link = await getUploadLink(path, overwrite: overwrite);
    if (link.href == null) {
      throw Exception('Failed to get upload link');
    }
    final body = OAuth2FileBody(fileStream, contentLength: contentLength);
    await client.put(link.href!, body: body, onProgress: onProgress);
  }

  @override
  Future<Stream<List<int>>> downloadFile(
    String path, {
    OAuth2ProgressCallback? onProgress,
  }) async {
    final link = await getDownloadLink(path);
    if (link.href == null) {
      throw Exception('Failed to get download link');
    }
    return client.getStream(link.href!, onProgress: onProgress);
  }

  @override
  Future<Link> createFolder(String path, {List<String>? fields}) async {
    final queryParams = _makeQueryParams(path: path, fields: fields);
    final json = await client.putJson(
      '$_baseUrl/resources',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> copyResource(
    String from,
    String path, {
    bool? overwrite,
    List<String>? fields,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      overwrite: overwrite,
      fields: fields,
    );
    // 'from' parameter is specific to copy/move and passed as query param 'from'
    queryParams['from'] = from;

    final json = await client.postJson(
      '$_baseUrl/resources/copy',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> moveResource(
    String from,
    String path, {
    bool? overwrite,
    List<String>? fields,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      overwrite: overwrite,
      fields: fields,
    );
    queryParams['from'] = from;

    final json = await client.postJson(
      '$_baseUrl/resources/move',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<dynamic> deleteResource(
    String path, {
    bool? permanently,
    List<String>? fields,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      permanently: permanently,
      fields: fields,
    );
    return await client.delete('$_baseUrl/resources', queryParams: queryParams);
  }

  @override
  Future<Link> publishResource(String path) async {
    final queryParams = _makeQueryParams(path: path);
    final json = await client.putJson(
      '$_baseUrl/resources/publish',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> unpublishResource(String path) async {
    final queryParams = _makeQueryParams(path: path);
    final json = await client.putJson(
      '$_baseUrl/resources/unpublish',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<String> getOperationStatus(String operationId) async {
    final json = await client.getJson('$_baseUrl/operations/$operationId');
    return json['status'] as String;
  }

  @override
  Future<Resource> getTrashResources({
    String? path,
    int? limit,
    int? offset,
    String? sort,
    String? previewSize,
    bool? previewCrop,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      limit: limit,
      offset: offset,
      sort: sort,
      previewSize: previewSize,
      previewCrop: previewCrop,
    );
    final json = await client.getJson(
      '$_baseUrl/trash/resources',
      queryParams: queryParams,
    );
    return Resource.fromJson(json);
  }

  @override
  Future<Link> restoreFromTrash(
    String path, {
    String? name,
    bool? overwrite,
  }) async {
    final queryParams = _makeQueryParams(
      path: path,
      name: name,
      overwrite: overwrite,
    );
    final json = await client.putJson(
      '$_baseUrl/trash/resources/restore',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<dynamic> deleteFromTrash({String? path}) async {
    final queryParams = _makeQueryParams(path: path);
    return await client.delete(
      '$_baseUrl/trash/resources',
      queryParams: queryParams,
    );
  }

  @override
  Future<Resource> getPublicResource(
    String publicKey, {
    String? path,
    String? sort,
    int? limit,
    int? offset,
    String? previewSize,
    bool? previewCrop,
  }) async {
    final queryParams = _makeQueryParams(
      publicKey: publicKey,
      path: path,
      sort: sort,
      limit: limit,
      offset: offset,
      previewSize: previewSize,
      previewCrop: previewCrop,
    );
    final json = await client.getJson(
      '$_baseUrl/public/resources',
      queryParams: queryParams,
    );
    return Resource.fromJson(json);
  }

  @override
  Future<Link> getPublicDownloadLink(String publicKey, {String? path}) async {
    final queryParams = _makeQueryParams(publicKey: publicKey, path: path);
    final json = await client.getJson(
      '$_baseUrl/public/resources/download',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }

  @override
  Future<Link> savePublicResourceToDisk(
    String publicKey, {
    String? path,
    String? name,
  }) async {
    final queryParams = _makeQueryParams(
      publicKey: publicKey,
      path: path,
      name: name,
    );
    final json = await client.postJson(
      '$_baseUrl/public/resources/save-to-disk',
      queryParams: queryParams,
    );
    return Link.fromJson(json);
  }
}
