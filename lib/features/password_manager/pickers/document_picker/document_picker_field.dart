import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/document_picker_modal.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Поле формы для выбора документа из хранилища.
///
/// Открывает [showDocumentPickerModal] по клику или клавиатурному вводу.
/// Поддерживает автозагрузку заголовка документа по [selectedDocumentId].
class DocumentPickerField extends ConsumerStatefulWidget {
  const DocumentPickerField({
    super.key,
    this.onDocumentSelected,
    this.selectedDocumentId,
    this.selectedDocumentTitle,
    this.label,
    this.hintText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе документа (id, title)
  final void Function(String? documentId, String? documentTitle)?
  onDocumentSelected;

  /// ID выбранного документа
  final String? selectedDocumentId;

  /// Отображаемый заголовок документа (загружается по id если не задан)
  final String? selectedDocumentTitle;

  /// Метка поля
  final String? label;

  /// Текст подсказки
  final String? hintText;

  /// Доступность поля
  final bool enabled;

  /// FocusNode для управления фокусом извне
  final FocusNode? focusNode;

  /// Автоматический фокус при монтировании
  final bool autofocus;

  @override
  ConsumerState<DocumentPickerField> createState() =>
      _DocumentPickerFieldState();
}

class _DocumentPickerFieldState extends ConsumerState<DocumentPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  String? _resolvedTitle;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant DocumentPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDocumentId != widget.selectedDocumentId) {
      _resolvedTitle = null;
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
    widget.onDocumentSelected?.call(null, null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    final result = await showDocumentPickerModal(context, ref);
    if (result != null) {
      widget.onDocumentSelected?.call(result.id, result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabel = widget.label ?? 'Выберите документ';
    final effectiveHint = widget.hintText ?? 'Выберите документ';

    String? effectiveTitle = widget.selectedDocumentTitle;

    if (widget.selectedDocumentId != null &&
        widget.selectedDocumentId!.isNotEmpty &&
        (widget.selectedDocumentTitle == null ||
            widget.selectedDocumentTitle!.isEmpty)) {
      if (_resolvedTitle != null) {
        effectiveTitle = _resolvedTitle;
      } else {
        final documentDao = ref.watch(documentDaoProvider);
        documentDao.when(
          data: (dao) {
            dao.getById(widget.selectedDocumentId!).then((result) {
              if (result != null) {
                final title = result.$1.name;
                if (mounted && _resolvedTitle != title) {
                  setState(() => _resolvedTitle = title);
                }
              }
            });
          },
          loading: () {},
          error: (_, _) {},
        );

        effectiveTitle = documentDao.when(
          data: (_) => _resolvedTitle ?? 'Загрузка...',
          loading: () => 'Загрузка...',
          error: (_, _) => null,
        );
      }
    }

    final hasValue = effectiveTitle != null && effectiveTitle.isNotEmpty;

    return Semantics(
      label: effectiveLabel,
      value: hasValue ? effectiveTitle : null,
      hint: hasValue ? null : effectiveHint,
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

          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openPicker();
            return KeyEventResult.handled;
          }

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
                  if (_isHovered) setState(() => _isHovered = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: effectiveLabel,
                      hintText: hasValue ? null : effectiveHint,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: isFocused
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: hasValue && widget.enabled
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: _handleClear,
                              tooltip: 'Очистить',
                            )
                          : null,
                    ),
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hasValue ? effectiveTitle! : effectiveHint,
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
