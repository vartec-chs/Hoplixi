import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final licenseKeysFilterProvider =
    NotifierProvider<LicenseKeysFilterNotifier, LicenseKeysFilter>(
      LicenseKeysFilterNotifier.new,
    );

class LicenseKeysFilterNotifier extends Notifier<LicenseKeysFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  LicenseKeysFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return LicenseKeysFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(LicenseKeysFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(LicenseKeysFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
