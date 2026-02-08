import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_drive_api/yandex_drive_api.dart';
import 'package:dotenv/dotenv.dart';

/// env YANDEX_CLIENT_ID, YANDEX_CLIENT_SECRET

void main() {
  late YandexDrive yandexDrive;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final file = File('./oauth2_account.json');
    final account = OAuth2Account(
      appPrefix: 'oauth2restclientexample',
      tokenStorage: OAuth2TokenStorageJson(file: file),
    );
    final provider = Yandex(
      clientId: env['YANDEX_CLIENT_ID']!,
      clientSecret: env['YANDEX_CLIENT_SECRET']!,
      redirectUri: 'http://localhost:8569/callback',
      scopes: [
        'login:email',
        'login:info',
        "cloud_api:disk.write",
        "cloud_api:disk.read",
        'cloud_api:disk.app_folder',
        'cloud_api:disk.info',
      ],
    );
    final serviceName = provider.name;

    account.addProvider(provider);

    // Попробовать загрузить существующий токен
    OAuth2Token? token;
    if (file.existsSync()) {
      try {
        token = await account.loadAccount(serviceName, 'vartecmvm');
      } catch (e) {
        // Игнорировать ошибки загрузки
      }
    }

    // Если токен не загружен, выполнить новый логин
    token ??= await account.newLogin(serviceName);

    if (token == null) {
      fail(
        'Token is null. Запустите авторизацию вручную: создайте отдельный скрипт или приложение для получения токена.',
      );
    }
    final client = await account.createClient(token);

    yandexDrive = YandexDrive(client);
  });

  Future<void> waitForOperation(String? operationId) async {
    if (operationId == null) return;
    var status = 'in-progress';
    while (status == 'in-progress') {
      await Future.delayed(const Duration(milliseconds: 500));
      status = await yandexDrive.getOperationStatus(operationId);
    }
    if (status == 'failed') {
      fail('Operation $operationId failed');
    }
  }

  test('getDiskInfo', () async {
    final diskInfo = await yandexDrive.getDiskInfo();
    expect(diskInfo.totalSpace, isNotNull);
    expect(diskInfo.usedSpace, isNotNull);
    expect(diskInfo.trashSize, isNotNull);
    print('Total space: ${diskInfo.totalSpace}');
    print('Used space: ${diskInfo.usedSpace}');
  });

  test('Folder operations', () async {
    final folderName = 'test_folder_${DateTime.now().millisecondsSinceEpoch}';

    // Create folder
    await yandexDrive.createFolder(folderName);

    // Get resource info
    var resource = await yandexDrive.getResource(folderName);
    expect(resource.name, folderName);
    expect(resource.type, 'dir');

    // Update resource
    resource = await yandexDrive.updateResource(
      folderName,
      customProperties: {'test_key': 'test_value'},
    );
    expect(resource.customProperties?['test_key'], 'test_value');

    // Delete folder
    await yandexDrive.deleteResource(folderName, permanently: true);

    // Verify deletion
    try {
      await yandexDrive.getResource(folderName);
      fail('Folder should be deleted');
    } catch (e) {
      // Expected exception
    }
  });

  test('getFiles', () async {
    final files = await yandexDrive.getFiles(limit: 5);
    expect(files.items, isNotNull);
  });

  test('getLastUploadedFiles', () async {
    final files = await yandexDrive.getLastUploadedFiles(limit: 5);
    expect(files.items, isNotNull);
  });

  test('getUploadLink', () async {
    final path = 'test_upload_${DateTime.now().millisecondsSinceEpoch}.txt';
    final link = await yandexDrive.getUploadLink(path, overwrite: true);
    expect(link.href, isNotNull);
    expect(link.method, 'PUT');
  });

  test('Copy and Move operations', () async {
    final folderName =
        'test_folder_cm_${DateTime.now().millisecondsSinceEpoch}';
    final copyName = '${folderName}_copy';
    final moveName = '${folderName}_moved';

    // Create folder
    await yandexDrive.createFolder(folderName);

    // Copy
    final copyLink = await yandexDrive.copyResource(folderName, copyName);
    await waitForOperation(copyLink.operationId);
    var copyResource = await yandexDrive.getResource(copyName);
    expect(copyResource.name, copyName);

    // Move
    final moveLink = await yandexDrive.moveResource(copyName, moveName);
    await waitForOperation(moveLink.operationId);
    var moveResource = await yandexDrive.getResource(moveName);
    expect(moveResource.name, moveName);

    // Clean up
    await yandexDrive.deleteResource(folderName, permanently: true);
    await yandexDrive.deleteResource(moveName, permanently: true);
  });

  test('Publish operations', () async {
    final folderName =
        'test_folder_pub_${DateTime.now().millisecondsSinceEpoch}';

    await yandexDrive.createFolder(folderName);

    // Publish
    await yandexDrive.publishResource(folderName);
    var resource = await yandexDrive.getResource(folderName);
    expect(resource.publicUrl, isNotNull);

    // Unpublish
    await yandexDrive.unpublishResource(folderName);
    resource = await yandexDrive.getResource(folderName);
    expect(resource.publicUrl, isNull);

    await yandexDrive.deleteResource(folderName, permanently: true);
  });

  test('Trash operations', () async {
    final folderName =
        'test_folder_trash_${DateTime.now().millisecondsSinceEpoch}';

    await yandexDrive.createFolder(folderName);

    // Delete to trash
    final deleteResult = await yandexDrive.deleteResource(
      folderName,
      permanently: false,
    );
    if (deleteResult is Map && deleteResult.containsKey('operation_id')) {
      await waitForOperation(deleteResult['operation_id'] as String);
    }

    // Check trash
    final trash = await yandexDrive.getTrashResources(path: folderName);
    expect(trash.name, folderName);

    // Restore
    final restoreLink = await yandexDrive.restoreFromTrash(folderName);
    await waitForOperation(restoreLink.operationId);

    final resource = await yandexDrive.getResource(folderName);
    expect(resource.name, folderName);

    // Delete permanently
    await yandexDrive.deleteResource(folderName, permanently: true);
  });

  test('Upload from URL and Download Link', () async {
    final path = 'test_upload_url_${DateTime.now().millisecondsSinceEpoch}.svg';
    final url = 'https://yastatic.net/s3/home/services/block/drive_new.svg';

    final link = await yandexDrive.uploadFileFromUrl(url, path);
    expect(link.href, isNotNull);

    if (link.operationId != null) {
      await waitForOperation(link.operationId);
    }

    // Check it exists
    final resource = await yandexDrive.getResource(path);
    expect(resource.name, path);

    // Get download link
    final downloadLink = await yandexDrive.getDownloadLink(path);
    expect(downloadLink.href, isNotNull);

    await yandexDrive.deleteResource(path, permanently: true);
  });

  test('Public Resource operations', () async {
    final folderName =
        'test_folder_public_ops_${DateTime.now().millisecondsSinceEpoch}';

    await yandexDrive.createFolder(folderName);
    await yandexDrive.publishResource(folderName);

    // Refresh resource to get public_key/url
    var resource = await yandexDrive.getResource(folderName);
    final publicKey = resource.publicKey;

    expect(publicKey, isNotNull);

    if (publicKey != null) {
      final publicResource = await yandexDrive.getPublicResource(publicKey);
      expect(publicResource.publicKey, publicKey);

      // Get public download link
      final publicDownloadLink = await yandexDrive.getPublicDownloadLink(
        publicKey,
      );
      expect(publicDownloadLink.href, isNotNull);

      // Save public resource to disk
      final savePath = '${folderName}_saved';
      final saveLink = await yandexDrive.savePublicResourceToDisk(
        publicKey,
        name: savePath,
      );
      if (saveLink.operationId != null) {
        await waitForOperation(saveLink.operationId);
      }

      // Note: savePublicResourceToDisk saves to the root if path is not full,
      // but here we used name. Let's check if it exists.
      // The API behavior for 'name' vs 'path' in save-to-disk:
      // path: Path to the folder in which the resource should be saved.
      // name: Filename.

      // Actually I used 'name' parameter in the test but passed it as a name.
      // Let's verify where it ended up. If path is null, it goes to root.

      final savedResource = await yandexDrive.getResource(savePath);
      expect(savedResource.name, savePath);

      await yandexDrive.deleteResource(savePath, permanently: true);
    }

    await yandexDrive.deleteResource(folderName, permanently: true);
  });

  test('Delete from Trash', () async {
    final folderName =
        'test_trash_del_${DateTime.now().millisecondsSinceEpoch}';
    await yandexDrive.createFolder(folderName);

    // Delete to trash
    final deleteResult = await yandexDrive.deleteResource(
      folderName,
      permanently: false,
    );
    if (deleteResult is Map && deleteResult.containsKey('operation_id')) {
      await waitForOperation(deleteResult['operation_id'] as String);
    }

    // Delete from trash
    final result = await yandexDrive.deleteFromTrash(path: folderName);
    if (result is Map && result.containsKey('operation_id')) {
      await waitForOperation(result['operation_id'] as String);
    }

    // Verify it's gone from trash
    try {
      await yandexDrive.getTrashResources(path: folderName);
      fail('Should be deleted from trash');
    } catch (e) {
      // expected
    }
  });
}
