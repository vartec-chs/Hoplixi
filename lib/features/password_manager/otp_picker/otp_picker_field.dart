import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/otp_picker/otp_picker_modal.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Виджет для выбора OTP
class OtpPickerField extends ConsumerStatefulWidget {
  const OtpPickerField({
    super.key,
    this.onOtpSelected,
    this.selectedOtpId,
    this.selectedOtpName,
    this.label = 'OTP',
    this.hintText = 'Выберите OTP',
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе OTP
  final Function(String? otpId, String? otpName)? onOtpSelected;

  /// ID выбранного OTP
  final String? selectedOtpId;

  /// Название выбранного OTP
  final String? selectedOtpName;

  /// Метка поля
  final String label;

  /// Подсказка
  final String hintText;

  /// Доступность поля
  final bool enabled;

  /// FocusNode для управления фокусом
  final FocusNode? focusNode;

  /// Автоматический фокус
  final bool autofocus;

  @override
  ConsumerState<OtpPickerField> createState() => _OtpPickerFieldState();
}

class _OtpPickerFieldState extends ConsumerState<OtpPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Закэшированное название OTP (для случая, когда передан только ID)
  String? _resolvedOtpName;

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant OtpPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Сбрасываем кэш если изменился ID OTP
    if (oldWidget.selectedOtpId != widget.selectedOtpId) {
      _resolvedOtpName = null;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _effectiveFocusNode.requestFocus();
    _openPicker();
  }

  void _handleClear() {
    if (!widget.enabled) return;
    widget.onOtpSelected?.call(null, null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    final result = await showOtpPickerModal(context, ref);
    if (result != null) {
      widget.onOtpSelected?.call(result.id, result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Получаем эффективное название OTP
    String? effectiveOtpName = widget.selectedOtpName;

    // Автоматически загружаем название OTP по ID, если название не передано
    if (widget.selectedOtpId != null &&
        widget.selectedOtpId!.isNotEmpty &&
        (widget.selectedOtpName == null || widget.selectedOtpName!.isEmpty)) {
      // Используем кэш, если уже загружено
      if (_resolvedOtpName != null) {
        effectiveOtpName = _resolvedOtpName;
      } else {
        // Загружаем через провайдер
        final otpDao = ref.watch(otpDaoProvider);

        otpDao.when(
          data: (dao) {
            // Загружаем асинхронно
            dao.getOtpById(widget.selectedOtpId!).then((otp) {
              if (otp != null) {
                final name = otp.issuer ?? otp.accountName ?? 'Без названия';
                if (_resolvedOtpName != name) {
                  if (mounted) {
                    setState(() {
                      _resolvedOtpName = name;
                    });
                  }
                }
              }
            });
          },
          loading: () {},
          error: (_, __) {},
        );

        // Показываем временный текст пока загружается
        effectiveOtpName = otpDao.when(
          data: (_) => _resolvedOtpName ?? 'Загрузка...',
          loading: () => 'Загрузка...',
          error: (_, __) => null,
        );
      }
    }

    // Определяем наличие значения
    final hasValue = effectiveOtpName != null && effectiveOtpName.isNotEmpty;

    return Semantics(
      label: widget.label,
      value: hasValue ? effectiveOtpName : null,
      hint: hasValue ? null : widget.hintText,
      button: true,
      enabled: widget.enabled,
      focusable: widget.enabled,
      onTap: widget.enabled ? _openPicker : null,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onKeyEvent: (node, event) {
          if (!widget.enabled) return KeyEventResult.ignored;

          // Enter, Space - открыть пикер
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openPicker();
            return KeyEventResult.handled;
          }

          // Delete, Backspace - очистить выбор
          if (event is KeyDownEvent &&
              hasValue &&
              (event.logicalKey == LogicalKeyboardKey.delete ||
                  event.logicalKey == LogicalKeyboardKey.backspace)) {
            _handleClear();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _effectiveFocusNode,
          builder: (context, child) {
            final isFocused = _effectiveFocusNode.hasFocus;

            return GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (_) {
                  if (widget.enabled && !_isHovered) {
                    setState(() => _isHovered = true);
                  }
                },
                onExit: (_) {
                  if (_isHovered) {
                    setState(() => _isHovered = false);
                  }
                },
                child: InputDecorator(
                  isFocused: isFocused,
                  isEmpty: !hasValue,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: widget.label,
                    hintText: widget.hintText,
                    prefixIcon: Icon(LucideIcons.smartphone),
                    suffixIcon: hasValue && widget.enabled
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _handleClear,
                            tooltip: 'Очистить',
                          )
                        : Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                  child: Text(
                    effectiveOtpName ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasValue
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
