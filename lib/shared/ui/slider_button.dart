import 'dart:math' as math;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Типы Slider Button для различных действий
enum SliderButtonType { confirm, delete, unlock, send }

/// Варианты цветов для Slider Button
enum SliderButtonVariant { normal, error, warning, info, success }

/// Типы анимации завершения
enum SliderButtonCompletionAnimation {
  /// Стандартная анимация заполнения
  fill,

  /// Новая анимация: уменьшение к центру и превращение в круг с галочкой
  shrinkToCircle,

  /// Современная анимация: слайдер уезжает вправо с затуханием, затем появляется галочка с отскоком
  slideAndFade,
}

/// Данные темы для Slider Button
class SliderButtonThemeData {
  final Color backgroundColor;
  final Color fillColor;
  final Color thumbColor;
  final Color iconColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final TextStyle textStyle;
  final double thumbSize; // Диаметр ползунка
  final Duration animationDuration;
  final IconData icon;

  const SliderButtonThemeData({
    required this.backgroundColor,
    required this.fillColor,
    required this.thumbColor,
    required this.iconColor,
    required this.textColor,
    required this.height,
    required this.borderRadius,
    required this.textStyle,
    required this.thumbSize,
    required this.animationDuration,
    required this.icon,
  });

  SliderButtonThemeData copyWith({
    Color? backgroundColor,
    Color? fillColor,
    Color? thumbColor,
    Color? iconColor,
    Color? textColor,
    double? height,
    double? borderRadius,
    TextStyle? textStyle,
    double? thumbSize,
    Duration? animationDuration,
    IconData? icon,
  }) {
    return SliderButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fillColor: fillColor ?? this.fillColor,
      thumbColor: thumbColor ?? this.thumbColor,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      textStyle: textStyle ?? this.textStyle,
      thumbSize: thumbSize ?? this.thumbSize,
      animationDuration: animationDuration ?? this.animationDuration,
      icon: icon ?? this.icon,
    );
  }
}

/// Inherited Widget для передачи темы Slider Button
class SliderButtonTheme extends InheritedWidget {
  final SliderButtonThemeData data;

  const SliderButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static SliderButtonThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SliderButtonTheme>()
        ?.data;
  }

  static SliderButtonThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    if (theme != null) return theme;

    // Fallback к базовой теме на основе Material Theme
    final materialTheme = Theme.of(context);
    return _getDefaultTheme(materialTheme, SliderButtonType.confirm);
  }

  @override
  bool updateShouldNotify(SliderButtonTheme oldWidget) {
    return data != oldWidget.data;
  }
}

/// Основной компонент Slider Button
class SliderButton extends StatefulWidget {
  final SliderButtonType type;
  final String text;
  final VoidCallback? onSlideComplete;
  final SliderButtonThemeData? theme;
  final bool enabled;
  final double? width;
  final bool resetAfterComplete;
  final Duration resetDelay;
  final bool showLoading;
  final Future<void> Function()? onSlideCompleteAsync;
  final SliderButtonVariant variant;
  final SliderButtonCompletionAnimation completionAnimation;
  final bool shimmerText;
  final bool destroyOnComplete;

  const SliderButton({
    super.key,
    required this.type,
    required this.text,
    this.onSlideComplete,
    this.onSlideCompleteAsync,
    this.theme,
    this.enabled = true,
    this.width,
    this.resetAfterComplete = true,
    this.resetDelay = const Duration(milliseconds: 500),
    this.showLoading = false,
    this.variant = SliderButtonVariant.normal,
    this.completionAnimation = SliderButtonCompletionAnimation.fill,
    this.shimmerText = false,
    this.destroyOnComplete = false,
  });

  @override
  State<SliderButton> createState() => _SliderButtonState();
}

class _SliderButtonState extends State<SliderButton>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shrinkController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shrinkAnimation;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeSlideAnimation;
  late Animation<double> _fadeOpacityAnimation;
  late Animation<double> _fadeCheckScaleAnimation;
  late Animation<double> _fadeCheckRotationAnimation;

  double _dragPosition = 0.0;
  bool _isDragging = false;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isDestroyed = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _shrinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Анимация для shrinkToCircle
    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _shrinkController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shrinkController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shrinkController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Анимации для slideAndFade
    _fadeSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInCubic),
      ),
    );

    _fadeOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _fadeCheckScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _fadeCheckRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Запускаем пульсацию при инициализации
    _startPulse();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _shrinkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startPulse() {
    if (!_isDragging && !_isCompleted && !_isLoading && widget.enabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _isDragging = true;
    });
    _stopPulse();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxWidth);
    });
  }

  void _onPanEnd(
    DragEndDetails details,
    double maxWidth,
    SliderButtonThemeData theme,
  ) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _isDragging = false;
    });

    // Проверяем, достиг ли слайдер конца
    if (_dragPosition >= maxWidth * 0.85) {
      _completeSlide(theme);
    } else {
      _resetSlide();
    }
  }

  void _completeSlide(SliderButtonThemeData theme) async {
    if (widget.showLoading) {
      setState(() {
        _isLoading = true;
        _dragPosition = _getMaxDragDistance();
      });

      HapticFeedback.mediumImpact();

      try {
        // Выполняем асинхронное действие если есть
        if (widget.onSlideCompleteAsync != null) {
          await widget.onSlideCompleteAsync!();
        } else {
          widget.onSlideComplete?.call();
        }

        // Показываем анимацию завершения после загрузки
        setState(() {
          _isLoading = false;
          _isCompleted = true;
        });

        if (widget.completionAnimation ==
            SliderButtonCompletionAnimation.shrinkToCircle) {
          _shrinkController.forward();
        } else if (widget.completionAnimation ==
            SliderButtonCompletionAnimation.slideAndFade) {
          _fadeController.forward();
        } else {
          _slideController.forward();
        }
      } catch (e) {
        // В случае ошибки сбрасываем состояние
        setState(() {
          _isLoading = false;
        });
        _resetSlide();
        return;
      }
    } else {
      // Обычная логика без загрузки
      setState(() {
        _isCompleted = true;
        _dragPosition = _getMaxDragDistance();
      });

      HapticFeedback.mediumImpact();

      if (widget.completionAnimation ==
          SliderButtonCompletionAnimation.shrinkToCircle) {
        _shrinkController.forward();
      } else if (widget.completionAnimation ==
          SliderButtonCompletionAnimation.slideAndFade) {
        _fadeController.forward();
      } else {
        _slideController.forward();
      }

      if (widget.onSlideCompleteAsync != null) {
        widget.onSlideCompleteAsync!();
      } else {
        widget.onSlideComplete?.call();
      }
    }

    if (widget.destroyOnComplete) {
      _destroyAfterCompletion(theme);
    } else if (widget.resetAfterComplete) {
      Future.delayed(widget.resetDelay, () {
        if (mounted) {
          _resetSlide();
        }
      });
    }
  }

  void _resetSlide() {
    final controller =
        widget.completionAnimation ==
            SliderButtonCompletionAnimation.shrinkToCircle
        ? _shrinkController
        : widget.completionAnimation ==
              SliderButtonCompletionAnimation.slideAndFade
        ? _fadeController
        : _slideController;

    controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _dragPosition = 0.0;
          _isCompleted = false;
          _isLoading = false;
        });
        _startPulse();
      }
    });
  }

  double _getMaxDragDistance() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0.0;

    final theme = widget.theme ?? SliderButtonTheme.of(context);
    final thumbInset = _getThumbInset(theme);
    return math.max(
      0.0,
      renderBox.size.width - theme.thumbSize - thumbInset * 2,
    );
  }

  double _getThumbInset(SliderButtonThemeData theme) {
    return math.max(6.0, (theme.height - theme.thumbSize) / 2);
  }

  Color _getThumbIconColor(SliderButtonThemeData theme, Color variantColor) {
    if (theme.thumbColor.computeLuminance() > 0.8) {
      return variantColor;
    }

    return theme.iconColor;
  }

  Duration _getCompletionAnimationDuration(SliderButtonThemeData theme) {
    switch (widget.completionAnimation) {
      case SliderButtonCompletionAnimation.shrinkToCircle:
        return _shrinkController.duration ?? const Duration(milliseconds: 600);
      case SliderButtonCompletionAnimation.slideAndFade:
        return _fadeController.duration ?? const Duration(milliseconds: 800);
      case SliderButtonCompletionAnimation.fill:
        return _slideController.duration ?? theme.animationDuration;
    }
  }

  void _destroyAfterCompletion(SliderButtonThemeData theme) {
    Future.delayed(_getCompletionAnimationDuration(theme), () {
      if (!mounted) return;

      setState(() {
        _isDestroyed = true;
      });
    });
  }

  Color _getVariantColor(BuildContext context, SliderButtonThemeData theme) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.variant) {
      case SliderButtonVariant.normal:
        return theme.fillColor;
      case SliderButtonVariant.error:
        return colorScheme.error;
      case SliderButtonVariant.warning:
        return Colors.orangeAccent.shade700;
      case SliderButtonVariant.info:
        return Colors.blueAccent.shade700;
      case SliderButtonVariant.success:
        return Colors.greenAccent.shade700;
    }
  }

  Widget _buildTextWidget(SliderButtonThemeData theme) {
    final textWidget = Text(
      widget.text,
      style: theme.textStyle.copyWith(
        color: widget.enabled
            ? theme.textColor
            : theme.textColor.withValues(alpha: 0.5),
      ),
    );

    if (widget.shimmerText && widget.enabled && !_isLoading) {
      return AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            widget.text,
            textStyle: theme.textStyle,
            colors: [
              theme.textColor,
              theme.textColor.withValues(alpha: 0.6),
              theme.fillColor,
              theme.textColor.withValues(alpha: 0.6),
              theme.textColor,
            ],
            speed: const Duration(milliseconds: 2000),
          ),
        ],
        repeatForever: true,
        isRepeatingAnimation: true,
      );
    }

    return textWidget;
  }

  // Анимация slideAndFade: слайдер уезжает вправо с затуханием
  Widget _buildSlideAndFadeAnimation(
    BuildContext context,
    BoxConstraints constraints,
    SliderButtonThemeData theme,
    Color variantColor,
  ) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final slideValue = _fadeSlideAnimation.value;
        final opacityValue = _fadeOpacityAnimation.value;
        final checkScale = _fadeCheckScaleAnimation.value;
        final checkRotation = _fadeCheckRotationAnimation.value;

        return Stack(
          children: [
            // Уезжающий слайдер
            if (opacityValue > 0.01)
              Positioned(
                left: constraints.maxWidth * slideValue * 0.3,
                child: Opacity(
                  opacity: opacityValue,
                  child: Container(
                    width: constraints.maxWidth,
                    height: theme.height,
                    decoration: BoxDecoration(
                      color: variantColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                  ),
                ),
              ),
            // Появляющаяся галочка с эффектами
            if (checkScale > 0.01)
              Center(
                child: Transform.scale(
                  scale: checkScale,
                  child: Transform.rotate(
                    angle: checkRotation,
                    child: Container(
                      width: theme.height,
                      height: theme.height,
                      decoration: BoxDecoration(
                        color: variantColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: variantColor.withValues(
                              alpha: 0.6 * checkScale,
                            ),
                            blurRadius: 20 * checkScale,
                            spreadRadius: 4 * checkScale,
                          ),
                          BoxShadow(
                            color: variantColor.withValues(
                              alpha: 0.3 * checkScale,
                            ),
                            blurRadius: 40 * checkScale,
                            spreadRadius: 8 * checkScale,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: theme.iconColor,
                        size: theme.thumbSize * 0.7,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Анимация уменьшения до круга с галочкой
  Widget _buildShrinkToCircleAnimation(
    BuildContext context,
    BoxConstraints constraints,
    SliderButtonThemeData theme,
    Color variantColor,
  ) {
    return AnimatedBuilder(
      animation: _shrinkController,
      builder: (context, child) {
        final shrinkValue = _shrinkAnimation.value;
        final circleValue = _circleAnimation.value;
        final checkValue = _checkAnimation.value;

        // Рассчитываем ширину и высоту
        final targetSize = theme.height;
        final currentWidth =
            constraints.maxWidth -
            (constraints.maxWidth - targetSize) * shrinkValue;

        // Рассчитываем borderRadius для плавного превращения в круг
        final borderRadius =
            theme.borderRadius +
            (targetSize / 2 - theme.borderRadius) * circleValue;

        return Center(
          child: Container(
            width: currentWidth,
            height: theme.height,
            decoration: BoxDecoration(
              color: variantColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: variantColor.withValues(alpha: 0.3 * circleValue),
                  blurRadius: 12 * circleValue,
                  spreadRadius: 2 * circleValue,
                ),
              ],
            ),
            child: Center(
              child: Transform.scale(
                scale: checkValue,
                child: Icon(
                  Icons.check,
                  color: theme.iconColor,
                  size: theme.thumbSize * 0.7,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDestroyed) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme ?? SliderButtonTheme.of(context);
    final variantColor = _getVariantColor(context, theme);
    final thumbInset = _getThumbInset(theme);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: SizedBox(
        width: widget.width,
        height: theme.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxDragDistance = math.max(
              0.0,
              constraints.maxWidth - theme.thumbSize - thumbInset * 2,
            );
            final progressWidth =
                (_dragPosition + theme.thumbSize + thumbInset * 2).clamp(
                  theme.thumbSize + thumbInset * 2,
                  constraints.maxWidth,
                );
            final thumbIconColor = _getThumbIconColor(theme, variantColor);
            final trackDecoration = BoxDecoration(
              color: widget.enabled
                  ? variantColor
                  : Color.lerp(theme.backgroundColor, Colors.white, 0.12) ??
                        theme.backgroundColor,
              borderRadius: BorderRadius.circular(theme.borderRadius),
              // border: Border.all(
              //   color: Colors.white.withValues(
              //     alpha: widget.enabled ? 0.18 : 0.12,
              //   ),
              // ),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: variantColor.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            );

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: trackDecoration,
              child: Stack(
                children: [
                  // Подсветка пройденного трека
                  AnimatedContainer(
                    duration: _isDragging
                        ? Duration.zero
                        : theme.animationDuration,
                    width: progressWidth,
                    height: theme.height,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: widget.enabled ? 0.14 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                  ),

                  // Текст
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.thumbSize + thumbInset * 2,
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: theme.animationDuration,
                        opacity: _isCompleted ? 0.0 : 1.0,
                        child: DefaultTextStyle(
                          style: theme.textStyle.copyWith(
                            color: widget.enabled
                                ? theme.textColor
                                : theme.textColor.withValues(alpha: 0.55),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!widget.enabled) ...[
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: theme.textColor.withValues(
                                    alpha: 0.55,
                                  ),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_isLoading) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Загрузка...',
                                  style: theme.textStyle.copyWith(
                                    color: theme.textColor,
                                  ),
                                ),
                              ] else
                                Flexible(child: _buildTextWidget(theme)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Thumb (ползунок)
                  AnimatedPositioned(
                    duration: _isDragging
                        ? Duration.zero
                        : theme.animationDuration,
                    left: thumbInset + _dragPosition,
                    top: thumbInset,
                    child: AnimatedOpacity(
                      duration: theme.animationDuration,
                      opacity: _isCompleted ? 0.0 : 1.0,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: (details) =>
                            _onPanUpdate(details, maxDragDistance),
                        onPanEnd: (details) =>
                            _onPanEnd(details, maxDragDistance, theme),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isDragging ? 1.08 : _pulseAnimation.value,
                              child: Container(
                                width: theme.thumbSize,
                                height: theme.thumbSize,
                                decoration: BoxDecoration(
                                  color: theme.thumbColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        widget.enabled ? 0.18 : 0.08,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isLoading
                                    ? Center(
                                        child: SizedBox(
                                          width: theme.thumbSize * 0.52,
                                          height: theme.thumbSize * 0.52,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  thumbIconColor.withOpacity(
                                                    widget.enabled ? 1.0 : 0.35,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        theme.icon,
                                        color: widget.enabled
                                            ? thumbIconColor
                                            : thumbIconColor.withValues(
                                                alpha: 0.35,
                                              ),
                                        size: theme.thumbSize * 0.52,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Анимация завершения
                  if (_isCompleted)
                    widget.completionAnimation ==
                            SliderButtonCompletionAnimation.shrinkToCircle
                        ? _buildShrinkToCircleAnimation(
                            context,
                            constraints,
                            theme,
                            variantColor,
                          )
                        : widget.completionAnimation ==
                              SliderButtonCompletionAnimation.slideAndFade
                        ? _buildSlideAndFadeAnimation(
                            context,
                            constraints,
                            theme,
                            variantColor,
                          )
                        : AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Container(
                                width:
                                    constraints.maxWidth *
                                    _slideAnimation.value,
                                height: theme.height,
                                decoration: BoxDecoration(
                                  color: variantColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(
                                    theme.borderRadius,
                                  ),
                                ),
                                child: Center(
                                  child: Transform.scale(
                                    scale: _slideAnimation.value,
                                    child: Icon(
                                      Icons.check,
                                      color: theme.iconColor,
                                      size: theme.thumbSize * 0.6,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Функция для получения темы по умолчанию на основе типа кнопки
SliderButtonThemeData _getDefaultTheme(
  ThemeData materialTheme,
  SliderButtonType type,
) {
  final colorScheme = materialTheme.colorScheme;

  switch (type) {
    case SliderButtonType.confirm:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
        fillColor: colorScheme.primary,
        thumbColor: Colors.white,
        iconColor: colorScheme.onPrimary,
        textColor: colorScheme.onPrimary,
        height: 56.0,
        borderRadius: 28.0,
        textStyle: (materialTheme.textTheme.bodyLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
        thumbSize: 40.0,
        animationDuration: const Duration(milliseconds: 280),
        icon: Icons.chevron_right_rounded,
      );

    case SliderButtonType.delete:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.error.withValues(alpha: 0.18),
        fillColor: colorScheme.error,
        thumbColor: Colors.white,
        iconColor: colorScheme.onError,
        textColor: colorScheme.onError,
        height: 56.0,
        borderRadius: 28.0,
        textStyle: (materialTheme.textTheme.bodyLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
        thumbSize: 40.0,
        animationDuration: const Duration(milliseconds: 280),
        icon: Icons.delete_outline,
      );

    case SliderButtonType.unlock:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.secondary.withValues(alpha: 0.18),
        fillColor: colorScheme.secondary,
        thumbColor: Colors.white,
        iconColor: colorScheme.onSecondary,
        textColor: colorScheme.onSecondary,
        height: 56.0,
        borderRadius: 28.0,
        textStyle: (materialTheme.textTheme.bodyLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
        thumbSize: 40.0,
        animationDuration: const Duration(milliseconds: 280),
        icon: Icons.lock_open_outlined,
      );

    case SliderButtonType.send:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.tertiary.withValues(alpha: 0.18),
        fillColor: colorScheme.tertiary,
        thumbColor: Colors.white,
        iconColor: colorScheme.onTertiary,
        textColor: colorScheme.onTertiary,
        height: 56.0,
        borderRadius: 28.0,
        textStyle: (materialTheme.textTheme.bodyLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
        thumbSize: 40.0,
        animationDuration: const Duration(milliseconds: 280),
        icon: Icons.send_outlined,
      );
  }
}

/// Предопределенные темы для быстрого использования
class SliderButtonThemes {
  static SliderButtonThemeData confirm(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.confirm);
  }

  static SliderButtonThemeData delete(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.delete);
  }

  static SliderButtonThemeData unlock(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.unlock);
  }

  static SliderButtonThemeData send(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.send);
  }
}
