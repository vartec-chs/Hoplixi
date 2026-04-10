import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_settings_page.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/shared/ui/button.dart';

void main() {
  testWidgets(
    'CloudSyncSettingsPage shows sync progress block and disables actions during sync',
    (tester) async {
      final token = AuthTokenEntry(
        id: 'token-1',
        provider: CloudSyncProvider.dropbox,
        accessToken: 'token',
        accountEmail: 'demo@example.com',
      );
      final binding = StoreSyncBinding(
        storeUuid: 'store-1',
        tokenId: token.id,
        provider: CloudSyncProvider.dropbox,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 2),
      );
      final status = StoreSyncStatus(
        isStoreOpen: true,
        storePath: '/tmp/store',
        storeUuid: 'store-1',
        storeName: 'Demo Store',
        binding: binding,
        token: token,
        localManifest: _manifest(revision: 2),
        remoteManifest: _manifest(revision: 2),
        compareResult: StoreVersionCompareResult.same,
        isSyncInProgress: true,
        syncProgress: const SnapshotSyncProgress(
          stage: SnapshotSyncStage.syncingAttachments,
          stepIndex: 4,
          totalSteps: 6,
          title: 'Синхронизация вложений',
          description: 'Скачиваем вложения и удаляем лишние локальные файлы.',
          transferProgress: SnapshotSyncTransferProgress(
            direction: SnapshotSyncTransferDirection.download,
            completedFiles: 12,
            totalFiles: 48,
            transferredBytes: 1024,
            totalBytes: 2048,
            currentFileName: 'archive.enc',
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStoreSyncProvider.overrideWith(
              () => _FakeCurrentStoreSyncNotifier(status),
            ),
            authTokensProvider.overrideWith(
              () => _FakeAuthTokensNotifier(<AuthTokenEntry>[token]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CloudSyncSettingsPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Синхронизация вложений'), findsOneWidget);
      expect(find.text('Шаг 4 из 6'), findsOneWidget);
      expect(find.text('Скачано 12 из 48 файлов'), findsOneWidget);
      expect(find.text('1.0 KB из 2.0 KB'), findsOneWidget);
      expect(find.text('Текущий файл: archive.enc'), findsOneWidget);

      expect(
        tester
            .widget<SmoothButton>(
              find.widgetWithText(SmoothButton, 'Обновить статус'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SmoothButton>(
              find.widgetWithText(
                SmoothButton,
                'Проверить синхронизацию сейчас',
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );
}

class _FakeCurrentStoreSyncNotifier extends CurrentStoreSyncNotifier {
  _FakeCurrentStoreSyncNotifier(this._status);

  final StoreSyncStatus _status;

  @override
  Future<StoreSyncStatus> build() async => _status;
}

class _FakeAuthTokensNotifier extends AuthTokensNotifier {
  _FakeAuthTokensNotifier(this._tokens);

  final List<AuthTokenEntry> _tokens;

  @override
  Future<List<AuthTokenEntry>> build() async => _tokens;
}

StoreManifest _manifest({required int revision}) {
  return StoreManifest(
    storeUuid: 'store-1',
    storeName: 'Demo Store',
    revision: revision,
    updatedAt: DateTime.utc(2025, 1, 1),
    snapshotId: 'snapshot-$revision',
    lastModifiedBy: const StoreManifestLastModifiedBy(
      deviceId: 'device',
      clientInstanceId: 'client',
      appVersion: '1.0.0',
    ),
    content: const StoreManifestContent(
      dbFile: StoreManifestDbFileContent(
        fileName: 'store.hplxdb',
        size: 10,
        sha256: 'db-hash',
      ),
      keyFile: StoreManifestKeyFileContent(sha256: 'key-hash', size: 5),
      attachments: StoreManifestAttachmentsContent(
        count: 1,
        totalSize: 2,
        manifestSha256: 'files-hash',
        filesHash: 'files-hash',
      ),
    ),
  );
}
