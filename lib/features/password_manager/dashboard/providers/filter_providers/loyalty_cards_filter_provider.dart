import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/old/models/filter/loyalty_cards_filter.dart';

import 'base_filter_provider.dart';

final loyaltyCardsFilterProvider =
    NotifierProvider.autoDispose<
      LoyaltyCardsFilterNotifier,
      LoyaltyCardsFilter
    >(LoyaltyCardsFilterNotifier.new);

class LoyaltyCardsFilterNotifier extends Notifier<LoyaltyCardsFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  LoyaltyCardsFilter build() {
    ref.listen(baseFilterProvider, (previous, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return LoyaltyCardsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(LoyaltyCardsFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(LoyaltyCardsFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
