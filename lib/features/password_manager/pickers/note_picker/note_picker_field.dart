import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_modal.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет для выбора заметки
class NotePickerField extends ConsumerStatefulWidget {
  const NotePickerField({
    super.key,
    this.onNoteSelected,
    this.selectedNoteId,
    this.selectedNoteName,
    this.label = 'Заметка',
    this.hintText = 'Выберите заметку',
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
  ConsumerState<NotePickerField> createState() => _NotePickerFieldState();
}

class _NotePickerFieldState extends ConsumerState<NotePickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Закэшированное название заметки (для случая, когда передан только ID)
  String? _resolvedNoteName;

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant NotePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Сбрасываем кэш если изменился ID заметки
    if (oldWidget.selectedNoteId != widget.selectedNoteId) {
      _resolvedNoteName = null;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Получаем эффективное название заметки
    String? effectiveNoteName = widget.selectedNoteName;

    // Автоматически загружаем название заметки по ID, если название не передано
    if (widget.selectedNoteId != null &&
        widget.selectedNoteId!.isNotEmpty &&
        (widget.selectedNoteName == null || widget.selectedNoteName!.isEmpty)) {
      // Используем кэш, если уже загружено
      if (_resolvedNoteName != null) {
        effectiveNoteName = _resolvedNoteName;
      } else {
        // Загружаем через провайдер
        final noteDao = ref.watch(noteDaoProvider);

        noteDao.when(
          data: (dao) {
            // Загружаем асинхронно
            dao.getById(widget.selectedNoteId!).then((note) {
              if (note != null && _resolvedNoteName != note.$1.name) {
                if (mounted) {
                  setState(() {
                    _resolvedNoteName = note.$1.name;
                  });
                }
              }
            });
          },
          loading: () {},
          error: (_, _) {},
        );

        // Показываем временный текст пока загружается
        effectiveNoteName = noteDao.when(
          data: (_) => _resolvedNoteName ?? 'Загрузка...',
          loading: () => 'Загрузка...',
          error: (_, _) => null,
        );
      }
    }

    // Определяем наличие значения
    final hasValue = effectiveNoteName != null && effectiveNoteName.isNotEmpty;

    return Semantics(
      label: widget.label,
      value: hasValue ? effectiveNoteName : null,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: widget.label,
                      hintText: widget.hintText,
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
                    child: Text(
                      effectiveNoteName ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.38),
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
