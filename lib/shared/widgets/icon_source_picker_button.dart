import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/db_core/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/db_core/models/enums/icon_source.dart';
import 'package:hoplixi/features/custom_icon_packs/picker/icon_pack_picker_modal.dart';
import 'package:hoplixi/features/password_manager/pickers/icon_picker/icon_picker.dart';

import 'icon_ref_preview.dart';

class IconSourcePickerButton extends ConsumerWidget {
  const IconSourcePickerButton({
    super.key,
    this.iconRef,
    required this.onChanged,
    required this.fallbackIcon,
    this.title = 'Иконка',
    this.subtitle,
    this.onBeforeOpenDbPicker,
    this.size = 72,
  });

  final IconRefDto? iconRef;
  final ValueChanged<IconRefDto?> onChanged;
  final IconData fallbackIcon;
  final String title;
  final String? subtitle;
  final Future<bool> Function(BuildContext context)? onBeforeOpenDbPicker;
  final double size;

  Future<void> _pickDbIcon(BuildContext context, WidgetRef ref) async {
    final canOpen = await onBeforeOpenDbPicker?.call(context) ?? true;
    if (!canOpen || !context.mounted) {
      return;
    }

    final selectedIconId = await showIconPickerModal(context, ref);
    if (selectedIconId == null || !context.mounted) {
      return;
    }

    onChanged(IconRefDto.db(selectedIconId));
  }

  Future<void> _pickIconPack(BuildContext context, WidgetRef ref) async {
    final selectedIconKey = await showIconPackPickerModal(
      context,
      ref,
      initialIconKey: iconRef?.source == IconSourceType.iconPack
          ? iconRef?.value
          : null,
    );
    if (selectedIconKey == null || !context.mounted) {
      return;
    }

    onChanged(IconRefDto.iconPack(selectedIconKey));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: IconRefPreview(
                  iconRef: iconRef,
                  fallbackIcon: fallbackIcon,
                  size: size * 0.46,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ??
                          'Можно выбрать иконку из базы или SVG из пользовательского пака.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _pickIconPack(context, ref),
                          icon: const Icon(Icons.collections_outlined),
                          label: const Text('Паки'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _pickDbIcon(context, ref),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Мои иконки'),
                        ),
                        if (iconRef != null)
                          TextButton.icon(
                            onPressed: () => onChanged(null),
                            icon: const Icon(Icons.clear),
                            label: const Text('Очистить'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (iconRef != null) ...[
            const SizedBox(height: 10),
            Text(
              iconRef!.source == IconSourceType.db
                  ? 'Источник: мои иконки'
                  : 'Источник: пак иконок',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
