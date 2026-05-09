import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _BulkMenuAction { favorite, pin, archive, category, tags, delete }

final class DashboardV2BulkBar extends StatelessWidget {
  const DashboardV2BulkBar({
    required this.selectedCount,
    required this.onClear,
    this.onBulkDelete,
    this.onBulkFavorite,
    this.bulkFavoriteLabel = 'В избранное',
    this.onBulkPin,
    this.bulkPinLabel = 'Закрепить',
    this.onBulkArchive,
    this.bulkArchiveLabel = 'В архив',
    this.onBulkAssignCategory,
    this.onBulkAssignTags,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback? onBulkDelete;
  final VoidCallback? onBulkFavorite;
  final String bulkFavoriteLabel;
  final VoidCallback? onBulkPin;
  final String bulkPinLabel;
  final VoidCallback? onBulkArchive;
  final String bulkArchiveLabel;
  final VoidCallback? onBulkAssignCategory;
  final VoidCallback? onBulkAssignTags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSmallScreen =
        MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;

    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: isSmallScreen
            ? Row(
                children: [
                  Icon(LucideIcons.check, color: colors.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Выбрано: $selectedCount',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SmoothButton(
                    onPressed: onClear,
                    label: 'Отмена',
                    type: SmoothButtonType.text,
                    size: SmoothButtonSize.preMedium,
                  ),
                  PopupMenuButton<_BulkMenuAction>(
                    tooltip: 'Массовые действия',
                    iconColor: colors.onSecondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _BulkMenuAction.favorite:
                          onBulkFavorite?.call();
                        case _BulkMenuAction.pin:
                          onBulkPin?.call();
                        case _BulkMenuAction.archive:
                          onBulkArchive?.call();
                        case _BulkMenuAction.category:
                          onBulkAssignCategory?.call();
                        case _BulkMenuAction.tags:
                          onBulkAssignTags?.call();
                        case _BulkMenuAction.delete:
                          onBulkDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.favorite,
                        enabled: onBulkFavorite != null,
                        child: Row(
                          children: [
                            const Icon(Icons.star_border, size: 18),
                            const SizedBox(width: 8),
                            Text(bulkFavoriteLabel),
                          ],
                        ),
                      ),
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.pin,
                        enabled: onBulkPin != null,
                        child: Row(
                          children: [
                            const Icon(Icons.push_pin_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(bulkPinLabel),
                          ],
                        ),
                      ),
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.archive,
                        enabled: onBulkArchive != null,
                        child: Row(
                          children: [
                            const Icon(Icons.archive_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(bulkArchiveLabel),
                          ],
                        ),
                      ),
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.category,
                        enabled: onBulkAssignCategory != null,
                        child: const Row(
                          children: [
                            Icon(Icons.category_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Категория'),
                          ],
                        ),
                      ),
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.tags,
                        enabled: onBulkAssignTags != null,
                        child: const Row(
                          children: [
                            Icon(Icons.sell_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Теги'),
                          ],
                        ),
                      ),
                      PopupMenuItem<_BulkMenuAction>(
                        value: _BulkMenuAction.delete,
                        enabled: onBulkDelete != null,
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Удалить'),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              )
            : Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check,
                          color: colors.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Выбрано: $selectedCount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SmoothButton(
                        onPressed: onBulkFavorite,
                        icon: const Icon(Icons.star_border),
                        label: bulkFavoriteLabel,
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onBulkPin,
                        icon: const Icon(Icons.push_pin_outlined),
                        label: bulkPinLabel,
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onBulkArchive,
                        icon: const Icon(Icons.archive_outlined),
                        label: bulkArchiveLabel,
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onBulkAssignCategory,
                        icon: const Icon(Icons.category_outlined),
                        label: 'Категория',
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onBulkAssignTags,
                        icon: const Icon(Icons.sell_outlined),
                        label: 'Теги',
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onBulkDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: 'Удалить',
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.error,
                        size: SmoothButtonSize.preMedium,
                      ),
                      SmoothButton(
                        onPressed: onClear,
                        label: 'Отмена',
                        type: SmoothButtonType.text,
                        size: SmoothButtonSize.preMedium,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
