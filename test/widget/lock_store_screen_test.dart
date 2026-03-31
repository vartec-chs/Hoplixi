import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/password_manager/lock_store/lock_store_screen.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

void main() {
  testWidgets(
    'LockStoreScreen shows snapshot sync progress and blocks actions while applying remote update',
    (tester) async {
      final status = StoreSyncStatus(
        isStoreOpen: false,
        isApplyingRemoteUpdate: true,
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
            mainStoreProvider.overrideWith(
              () => _FakeMainStoreNotifier(
                const DatabaseState(status: DatabaseStatus.locked),
              ),
            ),
            currentStoreSyncProvider.overrideWith(
              () => _FakeCurrentStoreSyncNotifier(status),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: LockStoreScreen())),
        ),
      );
      await tester.pump();

      expect(find.text('Загружаем новую версию хранилища'), findsOneWidget);
      expect(find.text('Синхронизация вложений'), findsOneWidget);
      expect(find.text('Шаг 4 из 6'), findsOneWidget);
      expect(find.text('Скачано 12 из 48 файлов'), findsOneWidget);
      expect(find.text('Текущий файл: archive.enc'), findsOneWidget);

      expect(
        tester
            .widget<SmoothButton>(
              find.widgetWithText(SmoothButton, 'Разблокировать'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SmoothButton>(
              find.widgetWithText(SmoothButton, 'Закрыть и выйти'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'LockStoreScreen shows pending apply state after remote snapshot download',
    (tester) async {
      final status = StoreSyncStatus(
        isStoreOpen: false,
        requiresUnlockToApply: true,
        lastResultType: SnapshotSyncResultType.downloaded,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainStoreProvider.overrideWith(
              () => _FakeMainStoreNotifier(
                const DatabaseState(status: DatabaseStatus.locked),
              ),
            ),
            currentStoreSyncProvider.overrideWith(
              () => _FakeCurrentStoreSyncNotifier(status),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: LockStoreScreen())),
        ),
      );
      await tester.pump();

      expect(find.text('Новая версия уже применена'), findsOneWidget);
      expect(find.text('Удалённый snapshot готов'), findsOneWidget);
      expect(
        tester
            .widget<SmoothButton>(
              find.widgetWithText(SmoothButton, 'Разблокировать'),
            )
            .onPressed,
        isNotNull,
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

class _FakeMainStoreNotifier extends MainStoreAsyncNotifier {
  _FakeMainStoreNotifier(this._state);

  final DatabaseState _state;

  @override
  Future<DatabaseState> build() async => _state;
}
