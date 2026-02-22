import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

final apiKeysFilterProvider =
    NotifierProvider<ApiKeysFilterNotifier, ApiKeysFilter>(
      ApiKeysFilterNotifier.new,
    );

class ApiKeysFilterNotifier extends Notifier<ApiKeysFilter> {
  static const String _logTag = 'ApiKeysFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  ApiKeysFilter build() {
    ref.listen(baseFilterProvider, (_, next) {
      state = state.copyWith(base: next);
    });

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return ApiKeysFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilter(ApiKeysFilter filter) {
    _debounceTimer?.cancel();
    state = filter;
  }

  void updateFilterDebounced(ApiKeysFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = filter;
    });
  }

  void setName(String? name) {
    final value = name?.trim();
    logDebug('ApiKey filter name: $value', tag: _logTag);
    state = state.copyWith(name: value?.isEmpty == true ? null : value);
  }

  void setService(String? service) {
    final value = service?.trim();
    state = state.copyWith(service: value?.isEmpty == true ? null : value);
  }

  void setTokenType(String? tokenType) {
    final value = tokenType?.trim();
    state = state.copyWith(tokenType: value?.isEmpty == true ? null : value);
  }

  void setEnvironment(String? environment) {
    final value = environment?.trim();
    state = state.copyWith(environment: value?.isEmpty == true ? null : value);
  }

  void setRevoked(bool? revoked) {
    state = state.copyWith(revoked: revoked);
  }

  void setHasExpiration(bool? hasExpiration) {
    state = state.copyWith(hasExpiration: hasExpiration);
  }

  void setSortField(ApiKeysSortField? sortField) {
    state = state.copyWith(sortField: sortField);
  }
}
