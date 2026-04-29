import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/main_db/models/db_state.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';

final routerRefreshNotifierProvider =
    NotifierProvider<RouterRefreshNotifier, int>(() => RouterRefreshNotifier());

class RouterRefreshNotifier extends Notifier<int> with ChangeNotifier {
  @override
  int build() {
    ref.listen<AsyncValue<DatabaseState>>(mainStoreProvider, (previous, next) {
      if (next.hasValue && previous?.value?.status != next.value!.status) {
        notifyListeners();
      }
    });

    ref.listen<StoreSyncStatus?>(closeStoreSyncStatusProvider, (
      previous,
      next,
    ) {
      if (previous != next) {
        notifyListeners();
      }
    });

    ref.listen(authFlowProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.previousRoute != next.previousRoute) {
        notifyListeners();
      }
    });

    return 0;
  }
}
