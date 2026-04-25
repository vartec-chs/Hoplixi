import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/otp_picker_modal.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Виджет для выбора OTP
class OtpPickerField extends ConsumerStatefulWidget {
  const OtpPickerField({
    super.key,
    this.onOtpSelected,
    this.selectedOtpId,
    this.selectedOtpName,
    this.label,
    this.hintText,
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
  final String? label;

  /// Подсказка
  final String? hintText;

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

    final effectiveLabel = widget.label ?? "Выберите OTP";
    final effectiveHintText = widget.hintText ?? "Выберите OTP";

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
            dao.getById(widget.selectedOtpId!).then((otp) {
              if (otp != null) {
                final name =
                    otp.$2.issuer ?? otp.$2.accountName ?? 'Без названия';
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
          error: (_, _) {},
        );

        // Показываем временный текст пока загружается
        effectiveOtpName = otpDao.when(
          data: (_) => _resolvedOtpName ?? "Загрузка...",
          loading: () => "Загрузка...",
          error: (_, _) => null,
        );
      }
    }

    // Определяем наличие значения
    final hasValue = effectiveOtpName != null && effectiveOtpName.isNotEmpty;

    return Semantics(
      label: effectiveLabel,
      value: hasValue ? effectiveOtpName : null,
      hint: hasValue ? null : effectiveHintText,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isHovered && widget.enabled
                        ? colorScheme.onSurface.withOpacity(0.04)
                        : Colors.transparent,
                  ),
                  child: InputDecorator(
                    isFocused: isFocused,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: effectiveLabel,
                      hintText: hasValue ? null : effectiveHintText,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: const Icon(LucideIcons.smartphone),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasValue)
                            ExcludeSemantics(
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: widget.enabled ? _handleClear : null,
                                tooltip: 'Очистить (Delete/Backspace)',
                              ),
                            ),
                          ExcludeSemantics(
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: widget.enabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hasValue ? effectiveOtpName! : effectiveHintText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: hasValue
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
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
