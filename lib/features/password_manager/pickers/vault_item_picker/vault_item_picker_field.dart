import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/pickers/vault_item_picker/vault_item_picker_modal.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

/// Поле выбора объекта хранилища для создания связи.
class VaultItemPickerField extends ConsumerStatefulWidget {
  const VaultItemPickerField({
    super.key,
    this.onItemSelected,
    this.selectedItemId,
    this.selectedItemName,
    this.selectedItemType,
    this.selectedItemDescription,
    this.excludeItemId,
    this.label,
    this.hintText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе или очистке объекта.
  final void Function(LinkedVaultItemCardDto? item)? onItemSelected;

  /// ID выбранного объекта.
  final String? selectedItemId;

  /// Название выбранного объекта, если оно уже известно вызывающему коду.
  final String? selectedItemName;

  /// Тип выбранного объекта, если он уже известен вызывающему коду.
  final VaultItemType? selectedItemType;

  /// Описание выбранного объекта, если оно уже известно вызывающему коду.
  final String? selectedItemDescription;

  /// ID объекта, который нужно исключить из выбора.
  final String? excludeItemId;

  /// Метка поля.
  final String? label;

  /// Подсказка.
  final String? hintText;

  /// Доступность поля.
  final bool enabled;

  /// FocusNode для управления фокусом извне.
  final FocusNode? focusNode;

  /// Автоматический фокус при монтировании.
  final bool autofocus;

  @override
  ConsumerState<VaultItemPickerField> createState() =>
      _VaultItemPickerFieldState();
}

class _VaultItemPickerFieldState extends ConsumerState<VaultItemPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  LinkedVaultItemCardDto? _resolvedItem;
  bool _isResolvingItem = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _syncResolvedItem();
  }

  @override
  void didUpdateWidget(covariant VaultItemPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedItemId != widget.selectedItemId ||
        oldWidget.selectedItemName != widget.selectedItemName ||
        oldWidget.selectedItemType != widget.selectedItemType ||
        oldWidget.selectedItemDescription != widget.selectedItemDescription) {
      _resolvedItem = null;
      _isResolvingItem = false;
      _syncResolvedItem();
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
    widget.onItemSelected?.call(null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    final result = await showVaultItemPickerModal(
      context,
      ref,
      excludeItemId: widget.excludeItemId,
    );
    if (result == null) return;

    widget.onItemSelected?.call(result);
  }

  Future<void> _syncResolvedItem() async {
    final itemId = widget.selectedItemId;
    final itemName = widget.selectedItemName;
    final itemType = widget.selectedItemType;

    if (itemId == null || itemId.isEmpty) {
      _resolvedItem = null;
      _isResolvingItem = false;
      return;
    }

    if (itemName != null && itemName.isNotEmpty && itemType != null) {
      _resolvedItem = LinkedVaultItemCardDto(
        id: itemId,
        name: itemName,
        vaultItemType: itemType,
        description: widget.selectedItemDescription,
      );
      _isResolvingItem = false;
      return;
    }

    if (!_isResolvingItem && mounted) {
      setState(() => _isResolvingItem = true);
    }

    final repos = await ref.read(vaultRepositories.future);
    final result = await repos.vaultItem.getById(itemId);
    final item = result.getOrNull()?.getOrNull();

    if (!mounted || widget.selectedItemId != itemId) return;

    setState(() {
      _resolvedItem = item == null
          ? null
          : LinkedVaultItemCardDto(
              id: item.itemId,
              name: item.name,
              vaultItemType: item.type,
              description: item.description,
            );
      _isResolvingItem = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabel = widget.label ?? 'Связанный объект';
    final effectiveHintText = widget.hintText ?? 'Выберите объект для связи';
    final effectiveItem = _effectiveSelectedItem;
    final hasValue = effectiveItem != null;
    final entityType = effectiveItem?.vaultItemType.toEntityType();

    return Semantics(
      label: effectiveLabel,
      value: hasValue ? effectiveItem.title : null,
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
                        entityType?.icon ?? Icons.link,
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
                          child: _buildFieldContent(
                            context,
                            item: effectiveItem,
                            entityLabel: entityType?.label,
                            hintText: effectiveHintText,
                            isLoading: _isResolvingItem,
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

  LinkedVaultItemCardDto? get _effectiveSelectedItem {
    final itemId = widget.selectedItemId;
    final itemName = widget.selectedItemName;
    final itemType = widget.selectedItemType;

    if (itemId != null &&
        itemId.isNotEmpty &&
        itemName != null &&
        itemName.isNotEmpty &&
        itemType != null) {
      return LinkedVaultItemCardDto(
        id: itemId,
        name: itemName,
        vaultItemType: itemType,
        description: widget.selectedItemDescription,
      );
    }

    return _resolvedItem;
  }

  Widget _buildFieldContent(
    BuildContext context, {
    required LinkedVaultItemCardDto? item,
    required String? entityLabel,
    required String hintText,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (item == null) {
      return Text(
        isLoading ? 'Загрузка...' : hintText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (entityLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            item.description?.isNotEmpty == true
                ? '$entityLabel · ${item.description}'
                : entityLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
