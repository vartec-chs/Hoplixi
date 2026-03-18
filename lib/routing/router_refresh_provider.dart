import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/providers/local_send_route_state_provider.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

final routerRefreshNotifierProvider =
    NotifierProvider<RouterRefreshNotifier, int>(() => RouterRefreshNotifier());

class RouterRefreshNotifier extends Notifier<int> with ChangeNotifier {
  @override
  int build() {
    ref.listen<AsyncValue<DatabaseState>>(mainStoreProvider, (previous, next) {
      if (next.hasValue &&
          (next.value!.isOpen ||
              next.value!.isClosed ||
              next.value!.isLocked)) {
        notifyListeners();
      }
    });

    // ref.listen<LocalSendRouteState>(localSendRouteStateProvider, (
    //   previous,
    //   next,
    // ) {
    //   if (previous != next) {
    //     notifyListeners();
    //   }
    // });

    return 0;
  }
}
