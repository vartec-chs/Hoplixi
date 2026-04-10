import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingStoreSettingsModalPageProvider =
    NotifierProvider<PendingStoreSettingsModalPageNotifier, int?>(
      PendingStoreSettingsModalPageNotifier.new,
    );

final isStoreSettingsModalOpenProvider =
    NotifierProvider<StoreSettingsModalOpenNotifier, bool>(
      StoreSettingsModalOpenNotifier.new,
    );

class PendingStoreSettingsModalPageNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setPage(int pageIndex) {
    state = pageIndex;
  }

  void clear() {
    state = null;
  }
}

class StoreSettingsModalOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool isOpen) {
    state = isOpen;
  }
}
