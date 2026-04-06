import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingStoreSettingsModalPageProvider =
    NotifierProvider<PendingStoreSettingsModalPageNotifier, int?>(
      PendingStoreSettingsModalPageNotifier.new,
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
