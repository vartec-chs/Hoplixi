import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_modal.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет для выбора заметки
class NotePickerField extends ConsumerStatefulWidget {
  const NotePickerField({
    super.key,
    this.onNoteSelected,
    this.selectedNoteId,
    this.selectedNoteName,
    this.label,
    this.hintText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе заметки
  final Function(String? noteId, String? noteName)? onNoteSelected;

  /// ID выбранной заметки
  final String? selectedNoteId;

  /// Название выбранной заметки
  final String? selectedNoteName;

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
  ConsumerState<NotePickerField> createState() => _NotePickerFieldState();
}

class _NotePickerFieldState extends ConsumerState<NotePickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Закэшированное название заметки (для случая, когда передан только ID)
  String? _resolvedNoteName;
  bool _isResolvingNoteName = false;

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _syncResolvedNoteName();
  }

  @override
  void didUpdateWidget(covariant NotePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Сбрасываем кэш если изменился ID заметки
    if (oldWidget.selectedNoteId != widget.selectedNoteId ||
        oldWidget.selectedNoteName != widget.selectedNoteName) {
      _resolvedNoteName = null;
      _isResolvingNoteName = false;
      _syncResolvedNoteName();
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
    widget.onNoteSelected?.call(null, null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    final result = await showNotePickerModal(context, ref);
    if (result != null) {
      widget.onNoteSelected?.call(result.id, result.name);
    }
  }

  Future<void> _syncResolvedNoteName() async {
    final noteId = widget.selectedNoteId;
    final noteName = widget.selectedNoteName;

    if (noteName != null && noteName.isNotEmpty) {
      _resolvedNoteName = noteName;
      _isResolvingNoteName = false;
      return;
    }

    if (noteId == null || noteId.isEmpty) {
      _resolvedNoteName = null;
      _isResolvingNoteName = false;
      return;
    }

    if (!_isResolvingNoteName && mounted) {
      setState(() => _isResolvingNoteName = true);
    }

    final noteDao = await ref.read(noteDaoProvider.future);
    final note = await noteDao.getById(noteId);

    if (!mounted || widget.selectedNoteId != noteId) return;

    setState(() {
      _resolvedNoteName = note?.$1.name;
      _isResolvingNoteName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabel = widget.label ?? "Выберите заметку";
    final effectiveHintText = widget.hintText ?? "Выберите заметку";

    // Получаем эффективное название заметки
    String? effectiveNoteName = widget.selectedNoteName;

    if (widget.selectedNoteId != null &&
        widget.selectedNoteId!.isNotEmpty &&
        (widget.selectedNoteName == null || widget.selectedNoteName!.isEmpty)) {
      effectiveNoteName =
          _resolvedNoteName ?? (_isResolvingNoteName ? "Загрузка..." : null);
    }

    // Определяем наличие значения
    final hasValue = effectiveNoteName != null && effectiveNoteName.isNotEmpty;

    return Semantics(
      label: effectiveLabel,
      value: hasValue ? effectiveNoteName : null,
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
                  ),
                  child: InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: effectiveLabel,
                      hintText: hasValue ? null : effectiveHintText,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: isFocused
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
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
                            hasValue ? effectiveNoteName! : effectiveHintText,
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
