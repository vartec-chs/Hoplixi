part of 'status_bar.dart';

/// Состояние статус-бара
@immutable
class StatusBarState {
  final String message;
  final Widget? icon;
  final Widget? rightContent;
  final bool loading;
  final bool hidden;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBarState({
    this.message = '',
    this.icon,
    this.rightContent,
    this.loading = false,
    this.hidden = false,
    this.backgroundColor,
    this.textColor,
  });

  StatusBarState copyWith({
    String? message,
    Widget? icon,
    Widget? rightContent,
    bool? loading,
    bool? hidden,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return StatusBarState(
      message: message ?? this.message,
      icon: icon ?? this.icon,
      rightContent: rightContent ?? this.rightContent,
      loading: loading ?? this.loading,
      hidden: hidden ?? this.hidden,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }
}

/// Notifier для управления состоянием статус-бара
class StatusBarStateNotifier extends Notifier<StatusBarState> {
  @override
  StatusBarState build() {
    return const StatusBarState();
  }

  /// Обновить сообщение
  void updateMessage(String message, {Widget? icon}) {
    state = state.copyWith(message: message, icon: icon);
  }

  /// Показать загрузку
  void showLoading(String message) {
    state = state.copyWith(message: message, loading: true);
  }

  /// Скрыть загрузку
  void hideLoading() {
    state = state.copyWith(loading: false);
  }

  /// Показать успех
  void showSuccess(String message) {
    state = state.copyWith(
      message: message,
      loading: false,
      icon: const Icon(Icons.check_circle, size: 14, color: Colors.green),
    );
  }

  /// Показать ошибку
  void showError(String message) {
    state = state.copyWith(
      message: message,
      loading: false,
      icon: const Icon(Icons.error, size: 14, color: Colors.red),
    );
  }

  /// Показать предупреждение
  void showWarning(String message) {
    state = state.copyWith(
      message: message,
      loading: false,
      icon: const Icon(Icons.warning, size: 14, color: Colors.orange),
    );
  }

  /// Показать информацию
  void showInfo(String message) {
    state = state.copyWith(
      message: message,
      loading: false,
      icon: const Icon(Icons.info, size: 14, color: Colors.blue),
    );
  }

  /// Очистить статус
  void clear() {
    state = const StatusBarState(message: 'Готово');
  }

  /// Скрыть/показать статус-бар
  void setHidden(bool hidden) {
    state = state.copyWith(hidden: hidden);
  }

  /// Установить правый контент
  void setRightContent(Widget? content) {
    state = state.copyWith(rightContent: content);
  }

  /// Установить цвета
  void setColors({Color? backgroundColor, Color? textColor}) {
    state = state.copyWith(
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

/// Provider для статус-бара
final statusBarStateProvider =
    NotifierProvider<StatusBarStateNotifier, StatusBarState>(
      StatusBarStateNotifier.new,
    );
