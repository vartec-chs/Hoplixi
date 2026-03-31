import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/password_manager/close_store/close_store_sync_screen.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

void main() {
  testWidgets(
    'CloseStoreSyncScreen shows live snapshot sync progress when available',
    (tester) async {
      const syncStatus = StoreSyncStatus(
        isStoreOpen: false,
        isSyncInProgress: true,
        syncProgress: SnapshotSyncProgress(
          stage: SnapshotSyncStage.transferringPrimaryFiles,
          stepIndex: 3,
          totalSteps: 6,
          title: 'Загрузка в облако',
          description: 'Передаём базу данных и ключ шифрования.',
          transferProgress: SnapshotSyncTransferProgress(
            direction: SnapshotSyncTransferDirection.upload,
            completedFiles: 1,
            totalFiles: 2,
            transferredBytes: 1024,
            totalBytes: 2048,
            currentFileName: 'store.hplxdb',
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainStoreProvider.overrideWith(
              () => _FakeMainStoreNotifier(
                const DatabaseState(
                  status: DatabaseStatus.closingSync,
                  name: 'Demo Store',
                  path: '/tmp/demo_store',
                ),
              ),
            ),
            currentStoreSyncProvider.overrideWith(
              () => _FakeCurrentStoreSyncNotifier(syncStatus),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CloseStoreSyncScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Закрытие хранилища'), findsOneWidget);
      expect(find.text('Загрузка в облако'), findsOneWidget);
      expect(find.text('Шаг 3 из 6'), findsOneWidget);
      expect(find.text('Загружено 1 из 2 файлов'), findsOneWidget);
      expect(find.text('Текущий файл: store.hplxdb'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'CloseStoreSyncScreen shows pending apply state without live progress',
    (tester) async {
      const syncStatus = StoreSyncStatus(
        isStoreOpen: false,
        requiresUnlockToApply: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainStoreProvider.overrideWith(
              () => _FakeMainStoreNotifier(
                const DatabaseState(status: DatabaseStatus.closingSync),
              ),
            ),
            currentStoreSyncProvider.overrideWith(
              () => _FakeCurrentStoreSyncNotifier(syncStatus),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CloseStoreSyncScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Удалённый snapshot готов'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

class _FakeCurrentStoreSyncNotifier extends CurrentStoreSyncNotifier {
  _FakeCurrentStoreSyncNotifier(this._status);

  final StoreSyncStatus _status;

  @override
  Future<StoreSyncStatus> build() async => _status;
}

class _FakeMainStoreNotifier extends MainStoreAsyncNotifier {
  _FakeMainStoreNotifier(this._state);

  final DatabaseState _state;

  @override
  Future<DatabaseState> build() async => _state;
}
