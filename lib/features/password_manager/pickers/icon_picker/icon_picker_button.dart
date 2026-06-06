import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/icon_ref_preview.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

import 'widgets/icon_picker_modal.dart';

/// Виджет для выбора иконки с превью и возможностью удаления.
class IconPickerButton extends ConsumerStatefulWidget {
  const IconPickerButton({
    super.key,
    this.selectedIconId,
    required this.onIconSelected,
    this.onBeforeOpenPicker,
    this.size = 120,
    this.hintText,
  });

  /// ID текущей выбранной ссылки на иконку.
  final String? selectedIconId;

  /// Callback при выборе иконки.
  final ValueChanged<String?> onIconSelected;

  /// Асинхронный callback перед открытием picker.
  /// Верните `false`, чтобы отменить открытие.
  final Future<bool> Function(BuildContext context)? onBeforeOpenPicker;

  /// Размер контейнера для превью.
  final double size;

  /// Текст подсказки когда иконка не выбрана.
  final String? hintText;

  @override
  ConsumerState<IconPickerButton> createState() => _IconPickerButtonState();
}

class _IconPickerButtonState extends ConsumerState<IconPickerButton> {
  IconRefDto? _iconRef;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIconId != null) {
      _loadIcon(widget.selectedIconId!);
    }
  }

  @override
  void didUpdateWidget(IconPickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIconId != oldWidget.selectedIconId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.selectedIconId != null) {
          _loadIcon(widget.selectedIconId!);
        } else {
          setState(() => _iconRef = null);
        }
      });
    }
  }

  Future<void> _loadIcon(String iconId) async {
    setState(() => _isLoading = true);

    try {
      final repos = await ref.read(vaultRepositories.future);
      final result = await repos.icon.getIconRef(iconId);
      final icon = result.getOrNull()?.getOrNull();

      if (!mounted) return;
      setState(() {
        _iconRef = icon == null
            ? null
            : IconRefDto(
                id: icon.id,
                iconSourceType: icon.iconSourceType,
                iconPackId: icon.iconPackId,
                iconValue: icon.iconValue,
                customIconId: icon.customIconId,
                color: icon.color,
                backgroundColor: icon.backgroundColor,
              );
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openIconPicker() async {
    final canOpen = await widget.onBeforeOpenPicker?.call(context) ?? true;
    if (!canOpen || !mounted) {
      return;
    }

    final selectedId = await showIconPickerModal(context, ref);

    if (selectedId != null && mounted) {
      widget.onIconSelected(selectedId);
      await _loadIcon(selectedId);
    }
  }

  void _clearIcon() {
    setState(() => _iconRef = null);
    widget.onIconSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: _openIconPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: _buildContent(context),
          ),
        ),
        if (_iconRef != null && !_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Удалить иконку',
                child: InkWell(
                  onTap: _clearIcon,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_iconRef != null) {
      return Center(
        child: IconRefPreview(
          iconRef: _iconRef,
          fallbackIcon: Icons.image_outlined,
          size: widget.size * 0.5,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          widget.hintText ?? 'Выберите иконку',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
