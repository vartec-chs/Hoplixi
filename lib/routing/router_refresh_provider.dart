import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

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

    ref.listen(authFlowProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.previousRoute != next.previousRoute) {
        notifyListeners();
      }
    });

    return 0;
  }
}
