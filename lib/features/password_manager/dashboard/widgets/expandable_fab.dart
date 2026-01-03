import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Направление раскрытия FAB кнопок
enum FABExpandDirection {
  /// Вертикально вверх (в столбик)
  up,

  /// Горизонтально вправо с раскладкой вниз
  rightDown,

  /// Горизонтально влево с раскладкой вверх
  leftUp,
}

/// Форма FAB кнопки
enum FABShape {
  /// Квадратная с анимацией к кругу при открытии
  square,

  /// Всегда круглая
  circle,
}

/// Callback для уведомления об изменении состояния открытия/закрытия
typedef FABStateChangeCallback = void Function(bool isOpen);

// =============================================================================
// FAB Action Data
// =============================================================================

/// Данные для действия в раскрывающемся FAB
@immutable
class FABActionData {
  const FABActionData({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
}

// =============================================================================
// Expandable FAB Widget
// =============================================================================

/// Раскрывающийся FAB с поддержкой двух режимов раскладки.
/// Все дочерние элементы отображаются в Overlay поверх остального UI.
@immutable
class ExpandableFAB extends StatefulWidget {
  const ExpandableFAB({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.direction = FABExpandDirection.up,
    this.shape = FABShape.square,
    this.spacing = 56.0,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.onStateChanged,
    this.showBackdrop = true,
    this.backdropOpacity = 0.4,
    this.isUseInNavigationRail = false,
    this.executeFirstActionDirectly = false,
  });

  /// Список действий для отображения
  final List<FABActionData> actions;

  /// Иконка главной кнопки (закрытое состояние)
  final IconData mainIcon;

  /// Иконка главной кнопки (открытое состояние)
  final IconData closeIcon;

  /// Направление раскрытия
  final FABExpandDirection direction;

  /// Форма FAB кнопки
  final FABShape shape;

  /// Флаг использования внутри NavigationRail
  final bool isUseInNavigationRail;

  /// Если true, при нажатии сразу выполняется первый экшен без раскрытия меню
  final bool executeFirstActionDirectly;

  /// Расстояние между элементами
  final double spacing;

  /// Длительность анимации
  final Duration duration;

  /// Кривая анимации открытия
  final Curve curve;

  /// Кривая анимации закрытия
  final Curve reverseCurve;

  /// Callback при изменении состояния
  final FABStateChangeCallback? onStateChanged;

  /// Показывать затемнённый фон
  final bool showBackdrop;

  /// Прозрачность фона (0.0 - 1.0)
  final double backdropOpacity;

  @override
  State<ExpandableFAB> createState() => ExpandableFABState();
}

class ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  static const double _fabSize = 56.0;

  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  bool _isOpen = false;

  /// Публичное свойство для проверки состояния
  bool get isOpen => _isOpen;

  /// Публичный метод для переключения состояния
  void toggle() => _toggle();

  /// Публичный метод для открытия
  void open() {
    if (!_isOpen) _toggle();
  }

  /// Публичный метод для закрытия
  void close() {
    if (_isOpen) _toggle();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant ExpandableFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем длительность если изменилась
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // Закрываем и переоткрываем при смене направления или формы
    if ((widget.direction != oldWidget.direction ||
            widget.shape != oldWidget.shape) &&
        _isOpen) {
      _closeImmediate();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    // Если включен режим прямого выполнения, выполняем первое действие
    if (widget.executeFirstActionDirectly) {
      if (widget.actions.isNotEmpty) {
        widget.actions.first.onPressed();
      }
      return;
    }

    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _createOverlay();
    _controller.forward();
    setState(() => _isOpen = true);
    widget.onStateChanged?.call(true);
  }

  void _close() {
    _controller.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() => _isOpen = false);
      }
    });
    widget.onStateChanged?.call(false);
  }

  void _closeImmediate() {
    _controller.reset();
    _removeOverlay();
    setState(() => _isOpen = false);
    widget.onStateChanged?.call(false);
  }

  void _executeAction(FABActionData action) {
    _close();
    action.onPressed();
  }

  Offset _getFabOffset() {
    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  Size _getFabSize() {
    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size(_fabSize, _fabSize);
  }

  void _createOverlay() {
    if (_overlayEntry != null) return;

    final fabOffset = _getFabOffset();
    final fabSize = _getFabSize();
    final fabCenter = widget.isUseInNavigationRail
        ? Offset(fabOffset.dx * 3.4, fabOffset.dy / 1.3)
        : Offset(
            fabOffset.dx + fabSize.width / 2,
            fabOffset.dy - fabSize.height / 4,
          );

    _overlayEntry = OverlayEntry(
      builder: (context) => _FABOverlayContent(
        controller: _controller,
        actions: widget.actions,
        direction: widget.direction,
        spacing: widget.spacing,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
        fabOffset: fabOffset,
        fabSize: fabSize,
        fabCenter: fabCenter,
        showBackdrop: widget.showBackdrop,
        backdropOpacity: widget.backdropOpacity,
        closeIcon: widget.closeIcon,
        onClose: _close,
        onActionPressed: _executeAction,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Масштаб: 1.0 -> 0.75 при открытии
        final scale = 1.0 - (_controller.value * 0.25);
        // Скругление: зависит от формы
        final borderRadius = widget.shape == FABShape.circle
            ? 28.0
            : 16.0 + (_controller.value * 12.0);

        return SizedBox(
          key: _fabKey,
          width: _fabSize,
          height: _fabSize,
          child: Transform.scale(
            scale: scale,
            child: Material(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(borderRadius),
              elevation: _isOpen ? 2 : 6,
              shadowColor: Colors.black38,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Center(
                  child: Transform.rotate(
                    angle: _controller.value * math.pi * 0.5,
                    child: Icon(
                      _isOpen ? widget.closeIcon : widget.mainIcon,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Overlay Content
// =============================================================================

class _FABOverlayContent extends StatelessWidget {
  const _FABOverlayContent({
    required this.controller,
    required this.actions,
    required this.direction,
    required this.spacing,
    required this.curve,
    required this.reverseCurve,
    required this.fabOffset,
    required this.fabSize,
    required this.fabCenter,
    required this.showBackdrop,
    required this.backdropOpacity,
    required this.closeIcon,
    required this.onClose,
    required this.onActionPressed,
  });

  final AnimationController controller;
  final List<FABActionData> actions;
  final FABExpandDirection direction;
  final double spacing;
  final Curve curve;
  final Curve reverseCurve;
  final Offset fabOffset;
  final Size fabSize;
  final Offset fabCenter;
  final bool showBackdrop;
  final double backdropOpacity;
  final IconData closeIcon;
  final VoidCallback onClose;
  final void Function(FABActionData) onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Затемнённый фон
            if (showBackdrop)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return ColoredBox(
                        color: Colors.black.withValues(
                          alpha: controller.value * backdropOpacity,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Кнопки действий
            ...List.generate(actions.length, (index) {
              return _AnimatedActionButton(
                index: index,
                totalCount: actions.length,
                controller: controller,
                action: actions[index],
                direction: direction,
                spacing: spacing,
                curve: curve,
                reverseCurve: reverseCurve,
                fabCenter: fabCenter,
                onPressed: () => onActionPressed(actions[index]),
              );
            }),

            // Кнопка закрытия (на месте FAB)
            Positioned(
              left: fabOffset.dx,
              top: fabOffset.dy - fabSize.height / 1.4,
              width: fabSize.width,
              height: fabSize.height,
              child: _CloseButton(
                controller: controller,
                icon: closeIcon,
                onTap: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Close Button
// =============================================================================

class _CloseButton extends StatelessWidget {
  const _CloseButton({
    required this.controller,
    required this.icon,
    required this.onTap,
  });

  final AnimationController controller;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: controller.value * math.pi * 0.5,
          child: FloatingActionButton(
            onPressed: onTap,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Icon(icon),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Animated Action Button
// =============================================================================

class _AnimatedActionButton extends StatelessWidget {
  const _AnimatedActionButton({
    required this.index,
    required this.totalCount,
    required this.controller,
    required this.action,
    required this.direction,
    required this.spacing,
    required this.curve,
    required this.reverseCurve,
    required this.fabCenter,
    required this.onPressed,
  });

  final int index;
  final int totalCount;
  final AnimationController controller;
  final FABActionData action;
  final FABExpandDirection direction;
  final double spacing;
  final Curve curve;
  final Curve reverseCurve;
  final Offset fabCenter;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Stagger animation: каждая кнопка появляется с небольшой задержкой
    final staggerDelay = index * 0.08;
    final staggerEnd = (0.6 + staggerDelay).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(staggerDelay, staggerEnd, curve: curve),
      reverseCurve: Interval(staggerDelay, staggerEnd, curve: reverseCurve),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        if (progress == 0.0) return const SizedBox.shrink();

        final position = _calculatePosition(progress);

        if (direction == FABExpandDirection.up) {
          // Для направления вверх — центрируем по горизонтали
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0), // Центрирование по X
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: progress,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            ),
          );
        }

        // Для других направлений — стандартное позиционирование
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: progress,
              alignment: _getScaleAlignment(),
              child: child,
            ),
          ),
        );
      },
      child: _ActionButtonWidget(action: action, onPressed: onPressed),
    );
  }

  Offset _calculatePosition(double progress) {
    switch (direction) {
      case FABExpandDirection.up:
        // Вверх от FAB, центрировано по горизонтали
        // fabCenter.dx — это центр FAB по X
        final targetY = fabCenter.dy - (index + 1) * spacing;
        final currentY = fabCenter.dy + (targetY - fabCenter.dy) * progress;
        // Возвращаем X как центр FAB, смещение сделает FractionalTranslation
        return Offset(fabCenter.dx, currentY - spacing / 2);

      case FABExpandDirection.rightDown:
        // Вправо от FAB, затем вниз
        final targetX = fabCenter.dx + 48; // Сдвиг вправо
        final targetY = fabCenter.dy - 24 + (index * spacing);
        final currentX = fabCenter.dx + (targetX - fabCenter.dx) * progress;
        final currentY = fabCenter.dy + (targetY - fabCenter.dy) * progress;
        return Offset(currentX, currentY);

      case FABExpandDirection.leftUp:
        // Влево от FAB, затем вниз
        final targetX = fabCenter.dx - 48; // Сдвиг влево
        final targetY = fabCenter.dy - 24 + (index * spacing);
        final currentX = fabCenter.dx + (targetX - fabCenter.dx) * progress;
        final currentY = fabCenter.dy + (targetY - fabCenter.dy) * progress;
        return Offset(currentX, currentY);
    }
  }

  Alignment _getScaleAlignment() {
    switch (direction) {
      case FABExpandDirection.up:
        return Alignment.center;
      case FABExpandDirection.rightDown:
        return Alignment.centerLeft;
      case FABExpandDirection.leftUp:
        return Alignment.centerRight;
    }
  }
}

// =============================================================================
// Action Button Widget
// =============================================================================

class _ActionButtonWidget extends StatelessWidget {
  const _ActionButtonWidget({required this.action, required this.onPressed});

  final FABActionData action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        action.backgroundColor ?? theme.colorScheme.secondaryContainer;
    final foregroundColor =
        action.foregroundColor ?? theme.colorScheme.onSecondaryContainer;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 20, color: foregroundColor),
              const SizedBox(width: 10),
              Text(
                action.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Legacy Compatibility (можно удалить после миграции)
// =============================================================================

/// @deprecated Use [FABActionData] instead
@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: foregroundColor, size: 20),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
