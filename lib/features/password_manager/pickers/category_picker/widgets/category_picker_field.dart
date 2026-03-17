import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/providers/category_info_provider.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/widgets/category_picker_modal.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Текстовое поле для выбора категории
class CategoryPickerField extends ConsumerStatefulWidget {
  const CategoryPickerField({
    super.key,
    this.onCategorySelected,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.label,
    this.hintText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.isFilter = false, // режим фильтра
    this.selectedCategoryIds = const [], // режим фильтра
    this.selectedCategoryNames = const [], // режим фильтра
    this.filterByType, // режим фильтра
    this.onCategoriesSelected, // режим фильтра
  });

  /// Коллбэк при выборе категории (одиночный режим)
  final Function(String? categoryId, String? categoryName)? onCategorySelected;

  /// Коллбэк при выборе категорий (режим фильтра)
  final Function(List<String> categoryIds, List<String> categoryNames)?
  onCategoriesSelected;

  /// ID выбранной категории (одиночный режим)
  final String? selectedCategoryId;

  /// Имя выбранной категории (одиночный режим)
  final String? selectedCategoryName;

  /// ID выбранных категорий (режим фильтра)
  final List<String> selectedCategoryIds;

  /// Имена выбранных категорий (режим фильтра)
  final List<String> selectedCategoryNames;

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

  /// Режим фильтра (множественный выбор)
  final bool isFilter;

  /// Типы категорий для фильтрации (только в режиме фильтра)
  final List<CategoryType>? filterByType;

  @override
  ConsumerState<CategoryPickerField> createState() =>
      _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends ConsumerState<CategoryPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Закэшированное имя категории (для случая, когда передан только ID)
  String? _resolvedCategoryName;

  /// Закэшированные имена категорий (для режима фильтра)
  List<String> _resolvedCategoryNames = [];
  bool _isResolvingCategoryName = false;
  bool _isResolvingCategoryNames = false;

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _syncResolvedCategoryData();
  }

  @override
  void didUpdateWidget(covariant CategoryPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Сбрасываем кэш если изменился ID категории
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _resolvedCategoryName = null;
    }

    // Сбрасываем кэш если изменились ID категорий в режиме фильтра
    if (!_listEquals(
      oldWidget.selectedCategoryIds,
      widget.selectedCategoryIds,
    )) {
      _resolvedCategoryNames = [];
    }

    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.selectedCategoryName != widget.selectedCategoryName ||
        !_listEquals(oldWidget.selectedCategoryIds, widget.selectedCategoryIds) ||
        !_listEquals(
          oldWidget.selectedCategoryNames,
          widget.selectedCategoryNames,
        )) {
      _isResolvingCategoryName = false;
      _isResolvingCategoryNames = false;
      _syncResolvedCategoryData();
    }
  }

  /// Сравнение списков
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    if (widget.isFilter) {
      widget.onCategoriesSelected?.call([], []);
    } else {
      widget.onCategorySelected?.call(null, null);
    }
    _effectiveFocusNode.requestFocus();
  }

  void _handleRemoveCategory(int index) {
    if (!widget.enabled || !widget.isFilter) return;
    final updatedIds = List<String>.from(widget.selectedCategoryIds);
    final updatedNames = List<String>.from(widget.selectedCategoryNames);
    updatedIds.removeAt(index);
    updatedNames.removeAt(index);
    widget.onCategoriesSelected?.call(updatedIds, updatedNames);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    if (widget.isFilter) {
      // Режим фильтра - множественный выбор
      await CategoryPickerModal.showMultiple(
        context: context,
        currentCategoryIds: widget.selectedCategoryIds,
        filterByType: widget.filterByType?.map((e) => e.value).toList(),
        onCategoriesSelected: (categoryIds, categoryNames) {
          widget.onCategoriesSelected?.call(categoryIds, categoryNames);
        },
      );
    } else {
      // Обычный режим - одиночный выбор
      await CategoryPickerModal.show(
        context: context,
        filterByType: widget.filterByType?.map((e) => e.value).toList(),
        currentCategoryId: widget.selectedCategoryId,
        onCategorySelected: (categoryId, categoryName) {
          widget.onCategorySelected?.call(categoryId, categoryName);
        },
      );
    }
  }

  Future<void> _syncResolvedCategoryData() async {
    if (widget.isFilter) {
      await _syncResolvedCategoryNames();
      return;
    }

    await _syncResolvedCategoryName();
  }

  Future<void> _syncResolvedCategoryName() async {
    final categoryId = widget.selectedCategoryId;
    final categoryName = widget.selectedCategoryName;

    if (categoryName != null && categoryName.isNotEmpty) {
      _resolvedCategoryName = categoryName;
      _isResolvingCategoryName = false;
      return;
    }

    if (categoryId == null || categoryId.isEmpty) {
      _resolvedCategoryName = null;
      _isResolvingCategoryName = false;
      return;
    }

    if (!_isResolvingCategoryName && mounted) {
      setState(() => _isResolvingCategoryName = true);
    }

    final info = await ref.read(categoryInfoProvider(categoryId).future);
    if (!mounted || widget.selectedCategoryId != categoryId) return;

    setState(() {
      _resolvedCategoryName = info?.name;
      _isResolvingCategoryName = false;
    });
  }

  Future<void> _syncResolvedCategoryNames() async {
    final categoryIds = widget.selectedCategoryIds;
    final categoryNames = widget.selectedCategoryNames;

    if (categoryNames.isNotEmpty) {
      _resolvedCategoryNames = categoryNames;
      _isResolvingCategoryNames = false;
      return;
    }

    if (categoryIds.isEmpty) {
      _resolvedCategoryNames = [];
      _isResolvingCategoryNames = false;
      return;
    }

    if (!_isResolvingCategoryNames && mounted) {
      setState(() => _isResolvingCategoryNames = true);
    }

    final infos = await ref.read(categoriesInfoProvider(categoryIds).future);
    if (!mounted || !_listEquals(widget.selectedCategoryIds, categoryIds)) {
      return;
    }

    setState(() {
      _resolvedCategoryNames = infos.map((i) => i.name).toList();
      _isResolvingCategoryNames = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabel = widget.label ?? "Выберите категорию";
    final effectiveHintText = widget.hintText ?? "Выберите категорию";

    // Получаем эффективное имя категории
    String? effectiveCategoryName = widget.selectedCategoryName;
    List<String> effectiveCategoryNames = widget.selectedCategoryNames;

    if (!widget.isFilter) {
      if (widget.selectedCategoryId != null &&
          widget.selectedCategoryId!.isNotEmpty &&
          (widget.selectedCategoryName == null ||
              widget.selectedCategoryName!.isEmpty)) {
        if (_resolvedCategoryName != null) {
          effectiveCategoryName = _resolvedCategoryName;
        } else {
          effectiveCategoryName = _isResolvingCategoryName
              ? "Загрузка..."
              : null;
        }
      }
    } else {
      if (widget.selectedCategoryIds.isNotEmpty &&
          widget.selectedCategoryNames.isEmpty) {
        if (_resolvedCategoryNames.isNotEmpty &&
            _resolvedCategoryNames.length ==
                widget.selectedCategoryIds.length) {
          effectiveCategoryNames = _resolvedCategoryNames;
        } else {
          effectiveCategoryNames = _isResolvingCategoryNames
              ? ["Загрузка..."]
              : [];
        }
      }
    }

    // Определяем наличие значения в зависимости от режима
    final hasValue = widget.isFilter
        ? effectiveCategoryNames.isNotEmpty
        : (effectiveCategoryName != null && effectiveCategoryName.isNotEmpty);

    return Semantics(
      label: effectiveLabel,
      value: hasValue
          ? (widget.isFilter
                ? effectiveCategoryNames.join(', ')
                : effectiveCategoryName)
          : null,
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
                    decoration: primaryInputDecoration(
                      context,
                      labelText: effectiveLabel,
                      hintText: hasValue ? null : effectiveHintText,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: const Icon(LucideIcons.folder),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasValue)
                            ExcludeSemantics(
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: widget.enabled ? _handleClear : null,
                                tooltip: widget.isFilter
                                    ? 'Очистить все (Delete/Backspace)'
                                    : 'Очистить (Delete/Backspace)',
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
                        child: widget.isFilter && hasValue
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  effectiveCategoryNames.length,
                                  (index) => _CategoryChip(
                                    label: effectiveCategoryNames[index],
                                    onRemove: widget.enabled
                                        ? () => _handleRemoveCategory(index)
                                        : null,
                                    enabled: widget.enabled,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  hasValue
                                      ? effectiveCategoryName!
                                      : effectiveHintText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: hasValue
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withOpacity(
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

/// Чип для отображения выбранной категории в режиме фильтра
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    this.onRemove,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? colorScheme.secondary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category,
            size: 14,
            color: enabled
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? colorScheme.onSecondaryContainer
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
                size: 16,
                color: enabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
