import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/lifecycle/auto_lock_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/widgets/update_marker.dart';

/// Простой статус-бар для отображения информации внизу экрана
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(statusBarStateProvider);

    if (statusState.hidden) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 28,
      decoration: BoxDecoration(
        color:
            statusState.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Левая часть - основной текст/статус
            Expanded(
              child: Row(
                children: [
                  if (statusState.loading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  if (statusState.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: statusState.icon!,
                    ),
                  Flexible(
                    child: Text(
                      statusState.message,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            statusState.textColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const _CurrentRouteWidget(),
                ],
              ),
            ),
            // Правая часть - информация о БД и дополнительный контент
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const _AutoLockTimerWidget(),
                const _UpdateMarkerWidget(),
                const _DatabaseStatusWidget(),
                const _BuildModeWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoLockTimerWidget extends ConsumerStatefulWidget {
  const _AutoLockTimerWidget();

  @override
  ConsumerState<_AutoLockTimerWidget> createState() =>
      _AutoLockTimerWidgetState();
}

class _AutoLockTimerWidgetState extends ConsumerState<_AutoLockTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autoLockState = ref.watch(autoLockProvider);

    if (!autoLockState.isWarning) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                'Автоблокировка: ${autoLockState.remainingSeconds}с',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения состояния базы данных
class _DatabaseStatusWidget extends ConsumerWidget {
  const _DatabaseStatusWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(mainStoreProvider);

    return dbState.when(
      data: (state) {
        if (state.isIdle || state.isClosed) {
          return _buildStatusChip(
            context,
            icon: Icons.storage_outlined,
            label: 'БД не открыта',
            color: Colors.grey,
          );
        }

        if (state.isLoading) {
          return _buildStatusChip(
            context,
            icon: Icons.hourglass_empty,
            label: 'Загрузка...',
            color: Colors.blue,
          );
        }

        if (state.isLocked) {
          return _buildStatusChip(
            context,
            icon: Icons.lock,
            label: state.name ?? 'Заблокировано',
            color: Colors.orange,
            tooltip: state.path,
          );
        }

        if (state.isOpen) {
          return _buildStatusChip(
            context,
            icon: Icons.check_circle,
            label: state.name ?? 'Открыта',
            color: Colors.green,
            tooltip: state.path,
          );
        }

        if (state.hasError) {
          return _buildStatusChip(
            context,
            icon: Icons.error,
            label: 'Ошибка БД',
            color: Colors.red,
            tooltip: state.error?.message,
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => _buildStatusChip(
        context,
        icon: Icons.hourglass_empty,
        label: 'Загрузка...',
        color: Colors.blue,
      ),
      error: (error, stack) => _buildStatusChip(
        context,
        icon: Icons.error,
        label: 'Ошибка',
        color: Colors.red,
        tooltip: error.toString(),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: chip);
    }

    return chip;
  }
}

/// Виджет для отображения маркера обновлений
class _UpdateMarkerWidget extends ConsumerWidget {
  const _UpdateMarkerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(dataUpdateStreamProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: UpdateMarker(updateStream: stream),
    );
  }
}

/// Виджет для отображения режима сборки (только в debug)
class _BuildModeWidget extends StatelessWidget {
  const _BuildModeWidget();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bug_report, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'Debug',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения текущего пути маршрута (только в debug)
class _CurrentRouteWidget extends StatelessWidget {
  const _CurrentRouteWidget();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final routePath = GoRouterState.of(context).uri.path;
    if (routePath.isEmpty || routePath == '/') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 12, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              routePath,
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

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
