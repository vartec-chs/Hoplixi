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
    this.label = 'Категория',
    this.hintText = 'Выберите категорию',
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

  /// Состояние наведения курсора
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Получаем эффективное имя категории
    String? effectiveCategoryName = widget.selectedCategoryName;
    List<String> effectiveCategoryNames = widget.selectedCategoryNames;

    // Автоматически загружаем имя категории по ID, если имя не передано
    if (!widget.isFilter) {
      // Одиночный режим
      if (widget.selectedCategoryId != null &&
          widget.selectedCategoryId!.isNotEmpty &&
          (widget.selectedCategoryName == null ||
              widget.selectedCategoryName!.isEmpty)) {
        // Используем кэш, если уже загружено
        if (_resolvedCategoryName != null) {
          effectiveCategoryName = _resolvedCategoryName;
        } else {
          // Загружаем через провайдер
          final categoryInfoAsync = ref.watch(
            categoryInfoProvider(widget.selectedCategoryId!),
          );

          categoryInfoAsync.whenData((info) {
            if (info != null && _resolvedCategoryName != info.name) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _resolvedCategoryName = info.name;
                  });
                }
              });
            }
          });

          // Показываем временный текст пока загружается
          effectiveCategoryName = categoryInfoAsync.when(
            data: (info) => info?.name,
            loading: () => 'Загрузка...',
            error: (_, __) => null,
          );
        }
      }
    } else {
      // Режим фильтра - множественный выбор
      if (widget.selectedCategoryIds.isNotEmpty &&
          widget.selectedCategoryNames.isEmpty) {
        // Используем кэш, если уже загружено
        if (_resolvedCategoryNames.isNotEmpty &&
            _resolvedCategoryNames.length ==
                widget.selectedCategoryIds.length) {
          effectiveCategoryNames = _resolvedCategoryNames;
        } else {
          // Загружаем через провайдер
          final categoriesInfoAsync = ref.watch(
            categoriesInfoProvider(widget.selectedCategoryIds),
          );

          categoriesInfoAsync.whenData((infos) {
            final names = infos.map((i) => i.name).toList();
            if (!_listEquals(_resolvedCategoryNames, names)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _resolvedCategoryNames = names;
                  });
                }
              });
            }
          });

          // Показываем временный текст пока загружается
          effectiveCategoryNames = categoriesInfoAsync.when(
            data: (infos) => infos.map((i) => i.name).toList(),
            loading: () => ['Загрузка...'],
            error: (_, __) => [],
          );
        }
      }
    }

    // Определяем наличие значения в зависимости от режима
    final hasValue = widget.isFilter
        ? effectiveCategoryNames.isNotEmpty
        : (effectiveCategoryName != null && effectiveCategoryName.isNotEmpty);

    return Semantics(
      label: widget.label,
      value: hasValue
          ? (widget.isFilter
                ? effectiveCategoryNames.join(', ')
                : effectiveCategoryName)
          : null,
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
                                      : widget.hintText,
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
