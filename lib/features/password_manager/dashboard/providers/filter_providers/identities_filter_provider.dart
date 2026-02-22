import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final identitiesFilterProvider =
    NotifierProvider<IdentitiesFilterNotifier, IdentitiesFilter>(
      IdentitiesFilterNotifier.new,
    );

class IdentitiesFilterNotifier extends Notifier<IdentitiesFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  IdentitiesFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return IdentitiesFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(IdentitiesFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(IdentitiesFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
