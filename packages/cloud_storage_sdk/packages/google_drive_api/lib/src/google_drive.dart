import 'package:oauth2restclient/oauth2restclient.dart';

import 'models/drive_list_response.dart';
import 'models/file_list_response.dart';
import 'models/gd_file.dart';
import 'interface.dart';

class GoogleDrive implements GoogleDriveApi {
  static const String theFields =
      'id,name,mimeType,createdTime,modifiedTime,size,parents,hasThumbnail,driveId';

  final OAuth2RestClient client;

  GoogleDrive(this.client);

  String _makeQuery({
    String? name,
    String? parentId,
    String? q,
    bool onlyFolder = false,
    bool onlyFile = false,
    String? mimeType,
  }) {
    List<String> conditions = [];

    if (name?.isNotEmpty ?? false) {
      conditions.add("name = '$name'");
    }

    if (parentId?.isNotEmpty ?? false) {
      conditions.add("'$parentId' in parents");
    }

    if (q?.isNotEmpty ?? false) {
      conditions.add(q!);
    }

    // 폴더만 검색하는 조건
    if (onlyFolder) {
      conditions.add("mimeType='application/vnd.google-apps.folder'");
    } else if (onlyFile) {
      conditions.add("mimeType!='application/vnd.google-apps.folder'");
    } else if (mimeType?.isNotEmpty ?? false) {
      conditions.add("mimeType='$mimeType'");
    }

    // 삭제된 파일 제외
    conditions.add("trashed=false");

    // 모든 조건을 AND로 결합
    return conditions.join(" and ");
  }

  Map<String, String> _makeQueryParams({
    String? q,
    String? orderBy,
    int? pageSize,
    String? driveId,
    String? fields,
    String? space,
    String? nextPageToken,
    bool? supportsAllDrives,
    List<String>? addParents,
    List<String>? removeParents,
  }) {
    final Map<String, String> queryParams = {};

    if (q?.isNotEmpty ?? false) {
      queryParams['q'] = q!;
    }

    if (orderBy?.isNotEmpty ?? false) {
      queryParams['orderBy'] = orderBy!;
    }

    if (pageSize != null) {
      queryParams['pageSize'] = pageSize.toString();
    }

    if (driveId?.isNotEmpty ?? false) {
      queryParams['driveId'] = driveId!;
      queryParams['includeItemsFromAllDrives'] = 'true';
      queryParams['supportsTeamDrives'] = 'true';
      queryParams['corpora'] = "drive";
    }

    if (supportsAllDrives != null) {
      queryParams['supportsAllDrives'] = supportsAllDrives.toString();
    }

    if (fields?.isNotEmpty ?? false) {
      queryParams['fields'] = fields!;
    }

    if (space?.isNotEmpty ?? false) {
      queryParams['space'] = space!;
    }

    if (nextPageToken?.isNotEmpty ?? false) {
      queryParams['pageToken'] = nextPageToken!;
    }

    if (addParents != null) {
      queryParams['addParents'] = addParents.join(',');
    }
    if (removeParents != null) {
      queryParams['removeParents'] = removeParents.join(',');
    }

    return queryParams;
  }

  @override
  Future<FileListResponse> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize = 1,
    String? driveId,
    String? fields = "files($theFields)",
    bool onlyFolder = false,
    bool onlyFile = false,
    String? mimeType,
    String? space = "drive",
    String? nextPageToken,
  }) async {
    var q = _makeQuery(
      name: name,
      parentId: parentId,
      q: query,
      onlyFolder: onlyFolder,
      onlyFile: onlyFile,
      mimeType: mimeType,
    );

    var queryParams = _makeQueryParams(
      q: q,
      orderBy: orderBy,
      pageSize: pageSize,
      driveId: driveId,
      fields: fields,
      space: space,
      nextPageToken: nextPageToken,
    );

    var url = 'https://www.googleapis.com/drive/v3/files';
    var json = await client.getJson(url, queryParams: queryParams);
    return FileListResponse.fromJson(json);
  }

  @override
  Future<DriveListResponse> listDrives({String? nextPageToken}) async {
    Map<String, String> queryParams = {"pageSize": "100"};
    if (nextPageToken?.isNotEmpty ?? false) {
      queryParams["pageToken"] = nextPageToken!;
    }

    var url = 'https://www.googleapis.com/drive/v3/drives';
    final json = await client.getJson(url);
    return DriveListResponse.fromJson(json);
  }

  @override
  Future<GDFile> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType = 'application/octet-stream',
    OAuth2ProgressCallback? onProgress,
  }) async {
    var url =
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart";

    var queryParams = _makeQueryParams(
      supportsAllDrives: true,
      fields: theFields,
    );

    final fileMeta = GDFile(
      createdTime: originalDate,
      mimeType: contentType,
      name: fileName,
      parents: [parentId],
    ).toJson();

    OAuth2JsonBody meta = OAuth2JsonBody(fileMeta);
    OAuth2FileBody file = OAuth2FileBody(
      dataStream,
      contentLength: fileSize!,
      contentType: contentType,
    );
    var body = OAuth2MultiBody.related(meta, file);

    var json = await client.postJson(
      url,
      body: body,
      queryParams: queryParams,
      onProgress: onProgress,
    );
    return GDFile.fromJson(json);
  }

  @override
  Future<GDFile> createFolder(
    String parentId,
    String folderName, {
    String? driveId,
  }) async {
    final fileMeta = GDFile(
      driveId: driveId,
      mimeType: 'application/vnd.google-apps.folder',
      name: folderName,
      parents: [parentId],
    ).toJson();

    var url = "https://www.googleapis.com/drive/v3/files";

    var queryParams = _makeQueryParams(
      supportsAllDrives: true,
      fields: theFields,
    );

    OAuth2JsonBody body = OAuth2JsonBody(fileMeta);

    var json = await client.postJson(url, body: body, queryParams: queryParams);
    return GDFile.fromJson(json);
  }

  @override
  Future<GDFile> getFile(String fileId) async {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId";
    var queryParams = _makeQueryParams(
      fields: theFields,
      supportsAllDrives: true,
    );
    var json = await client.getJson(url, queryParams: queryParams);
    return GDFile.fromJson(json);
  }

  @override
  Future<GDFile> updateFile(
    String fileId, {
    String? fileName,
    List<String>? addParents,
    List<String>? removeParents,
  }) async {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId";

    var queryParams = _makeQueryParams(
      fields: theFields,
      supportsAllDrives: true,
      addParents: addParents,
      removeParents: removeParents,
    );

    var file = GDFile(name: fileName);
    var body = OAuth2JsonBody(file.toJson());

    var response = await client.patchJson(
      url,
      body: body,
      queryParams: queryParams,
    );
    return GDFile.fromJson(response);
  }

  @override
  Future<Stream<List<int>>> downloadFile(
    String fileId, {
    OAuth2ProgressCallback? onProgress,
  }) async {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    var stream = await client.getStream(url, onProgress: onProgress);
    return stream;
  }

  @override
  Future<void> delete(String fileId) async {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId";

    var queryParams = _makeQueryParams(supportsAllDrives: true);

    await client.delete(url, queryParams: queryParams);
  }

  @override
  Future<GDFile> copyFile(String fromId, String toId) async {
    var url = "https://www.googleapis.com/drive/v3/files/$fromId/copy";
    var queryParams = _makeQueryParams(
      fields: theFields,
      supportsAllDrives: true,
    );
    final copied = GDFile(parents: [toId]);
    var body = OAuth2JsonBody(copied.toJson());
    var response = await client.postJson(
      url,
      body: body,
      queryParams: queryParams,
    );
    return GDFile.fromJson(response);
  }
}
