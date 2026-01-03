import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import 'widgets/icon_picker_modal.dart';

/// Виджет для выбора иконки с превью и возможностью удаления
class IconPickerButton extends ConsumerStatefulWidget {
  /// ID текущей выбранной иконки (опционально)
  final String? selectedIconId;

  /// Callback при выборе иконки
  final ValueChanged<String?> onIconSelected;

  /// Размер контейнера для превью
  final double size;

  /// Текст подсказки когда иконка не выбрана
  final String? hintText;

  const IconPickerButton({
    super.key,
    this.selectedIconId,
    required this.onIconSelected,
    this.size = 120,
    this.hintText,
  });

  @override
  ConsumerState<IconPickerButton> createState() => _IconPickerButtonState();
}

class _IconPickerButtonState extends ConsumerState<IconPickerButton> {
  Uint8List? _iconData;
  String? _iconType;
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
          setState(() {
            _iconData = null;
            _iconType = null;
          });
        }
      });
    }
  }

  Future<void> _loadIcon(String iconId) async {
    setState(() => _isLoading = true);

    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      final icon = await iconDao.getIconById(iconId);

      if (icon != null && mounted) {
        setState(() {
          _iconData = icon.data;
          _iconType = icon.type.toString();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Ошибка загрузки иконки: $e');
    }
  }

  Future<void> _openIconPicker() async {
    final selectedId = await showIconPickerModal(context, ref);

    if (selectedId != null && mounted) {
      widget.onIconSelected(selectedId);
      await _loadIcon(selectedId);
    }
  }

  void _clearIcon() {
    setState(() {
      _iconData = null;
      _iconType = null;
    });
    widget.onIconSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Основной контейнер
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
        // Кнопка удаления (только если иконка выбрана)
        if (_iconData != null && !_isLoading)
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
                    decoration: BoxDecoration(
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

    if (_iconData != null && _iconType != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildIconPreview(),
      );
    }

    // Пустое состояние - показываем hint
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
          widget.hintText ?? 'Выбрать иконку',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    final isSvg = _iconType == 'svg';

    if (isSvg) {
      return SvgPicture.memory(
        _iconData!,
        fit: BoxFit.contain,
        placeholderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Image.memory(
        _iconData!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          );
        },
      );
    }
  }
}
