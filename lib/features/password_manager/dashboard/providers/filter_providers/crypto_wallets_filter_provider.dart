import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final cryptoWalletsFilterProvider =
    NotifierProvider<CryptoWalletsFilterNotifier, CryptoWalletsFilter>(
      CryptoWalletsFilterNotifier.new,
    );

class CryptoWalletsFilterNotifier extends Notifier<CryptoWalletsFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CryptoWalletsFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return CryptoWalletsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(CryptoWalletsFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(CryptoWalletsFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
