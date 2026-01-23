import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для управления поисковым запросом в icon picker
final iconPickerSearchProvider =
    NotifierProvider<IconPickerSearchNotifier, String>(
      () => IconPickerSearchNotifier(),
    );

/// Notifier для управления поиском с дебаунсингом
class IconPickerSearchNotifier extends Notifier<String> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  String build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return '';
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = query.trim();
    });
  }

  /// Очистить поиск
  void clear() {
    _debounceTimer?.cancel();
    state = '';
  }
}
