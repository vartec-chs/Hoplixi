import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_card_compat.dart';

import 'base_filter_provider.dart';

final sshKeysFilterProvider =
    NotifierProvider.autoDispose<SshKeysFilterNotifier, SshKeysFilter>(
      SshKeysFilterNotifier.new,
    );

class SshKeysFilterNotifier extends Notifier<SshKeysFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  SshKeysFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return SshKeysFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(SshKeysFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(SshKeysFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
