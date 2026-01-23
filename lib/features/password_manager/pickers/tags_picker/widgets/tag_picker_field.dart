import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_modal.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Текстовое поле для выбора тегов с множественным выбором
class TagPickerField extends StatefulWidget {
  const TagPickerField({
    super.key,
    this.onTagsSelected,
    this.selectedTagIds = const [],
    this.selectedTagNames = const [],
    this.label = 'Теги',
    this.hintText = 'Выберите теги',
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.isFilter = false,
    this.maxTagPicks,
    this.filterByType,
  });

  /// Коллбэк при выборе тегов
  final Function(List<String> tagIds, List<String> tagNames)? onTagsSelected;

  /// ID выбранных тегов
  final List<String> selectedTagIds;

  /// Имена выбранных тегов
  final List<String> selectedTagNames;

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

  /// Режим фильтра (множественный выбор)
  final bool isFilter;

  /// Максимальное количество выбираемых тегов (null = без ограничений)
  final int? maxTagPicks;

  /// Тип тегов для фильтрации (только в режиме фильтра)
  final List<TagType?>? filterByType;

  @override
  State<TagPickerField> createState() => _TagPickerFieldState();
}

class _TagPickerFieldState extends State<TagPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
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
    widget.onTagsSelected?.call([], []);
    _effectiveFocusNode.requestFocus();
  }

  void _handleRemoveTag(int index) {
    if (!widget.enabled) return;
    final updatedIds = List<String>.from(widget.selectedTagIds);
    final updatedNames = List<String>.from(widget.selectedTagNames);
    updatedIds.removeAt(index);
    updatedNames.removeAt(index);
    widget.onTagsSelected?.call(updatedIds, updatedNames);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    await TagPickerModal.show(
      context: context,
      currentTagIds: widget.selectedTagIds,
      maxTagPicks: widget.maxTagPicks,
      filterByType: widget.filterByType,
      onTagsSelected: (tagIds, tagNames) {
        widget.onTagsSelected?.call(tagIds, tagNames);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasValue = widget.selectedTagNames.isNotEmpty;

    return Semantics(
      label: widget.label,
      value: hasValue ? widget.selectedTagNames.join(', ') : null,
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
                    color: _isHovered && widget.enabled
                        ? colorScheme.onSurface.withOpacity(0.04)
                        : Colors.transparent,
                  ),
                  child: InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: widget.label,
                      hintText: hasValue ? null : widget.hintText,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: Icon(LucideIcons.tag),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasValue)
                            ExcludeSemantics(
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: widget.enabled ? _handleClear : null,
                                tooltip: 'Очистить все (Delete/Backspace)',
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
                    isFocused: isFocused,
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: hasValue
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  widget.selectedTagNames.length,
                                  (index) => _TagChip(
                                    label: widget.selectedTagNames[index],
                                    onRemove: widget.enabled
                                        ? () => _handleRemoveTag(index)
                                        : null,
                                    enabled: widget.enabled,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.hintText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
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

/// Чип для отображения выбранного тега
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.onRemove, required this.enabled});

  final String label;
  final VoidCallback? onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.primaryContainer.withOpacity(0.15)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag, size: 14, color: Colors.grey),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? colorScheme.onSecondary
                  : colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.close,
                size: 14,
                color: enabled
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
