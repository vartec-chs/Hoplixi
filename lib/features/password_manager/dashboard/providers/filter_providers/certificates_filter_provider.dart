import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final certificatesFilterProvider =
    NotifierProvider<CertificatesFilterNotifier, CertificatesFilter>(
      CertificatesFilterNotifier.new,
    );

class CertificatesFilterNotifier extends Notifier<CertificatesFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CertificatesFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() => _debounceTimer?.cancel());

    return CertificatesFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(CertificatesFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(CertificatesFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }
}
