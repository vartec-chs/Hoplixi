import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/services/auth_tokens_service.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform({
    required this.tempPath,
    required this.appSupportPath,
    required this.appDocsPath,
  });

  final String tempPath;
  final String appSupportPath;
  final String appDocsPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => appDocsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveBoxManager hiveBoxManager;
  late AuthTokensService service;

  AuthTokenEntry buildToken({
    required String id,
    required String accessToken,
    required String accountEmail,
  }) {
    return AuthTokenEntry(
      id: id,
      provider: CloudSyncProvider.google,
      accessToken: accessToken,
      refreshToken: 'refresh-$id',
      appCredentialId: 'credential-google',
      accountEmail: accountEmail,
      accountName: accountEmail,
    );
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(const <String, String>{});
    tempDir = await Directory.systemTemp.createTemp(
      'hoplixi_auth_tokens_test_',
    );

    PathProviderPlatform.instance = FakePathProviderPlatform(
      tempPath: p.join(tempDir.path, 'temp'),
      appSupportPath: p.join(tempDir.path, 'support'),
      appDocsPath: p.join(tempDir.path, 'docs'),
    );

    hiveBoxManager = HiveBoxManager(const FlutterSecureStorage());
    await hiveBoxManager.initialize();
    service = AuthTokensService(hiveBoxManager);
    await service.initialize();
  });

  tearDown(() async {
    await service.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'importTokens updates equivalent token instead of creating duplicate',
    () async {
      final first = buildToken(
        id: 'token-1',
        accessToken: 'access-1',
        accountEmail: 'user@example.com',
      );
      final second = buildToken(
        id: 'token-2',
        accessToken: 'access-2',
        accountEmail: 'USER@example.com',
      );

      final result = await service.importTokens([first, second]);
      final allTokens = await service.getAllTokens();

      expect(result.created, 1);
      expect(result.updated, 1);
      expect(allTokens, hasLength(1));
      expect(allTokens.single.accessToken, 'access-2');
      expect(allTokens.single.refreshToken, 'refresh-token-2');
    },
  );
}
