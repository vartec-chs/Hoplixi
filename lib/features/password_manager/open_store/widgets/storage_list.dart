import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/widgets/storage_card.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Список доступных хранилищ
class StorageList extends StatelessWidget {
  final List<StorageInfo> storages;
  final StorageInfo? selectedStorage;
  final void Function(StorageInfo) onStorageSelected;
  final void Function(StorageInfo)? onStorageDelete;
  final bool showCreateButton;

  const StorageList({
    super.key,
    required this.storages,
    required this.selectedStorage,
    required this.onStorageSelected,
    this.onStorageDelete,
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (storages.isEmpty) {
      if (!showCreateButton) {
        return const SizedBox.shrink();
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Нет доступных хранилищ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте новое хранилище или\nимпортируйте существующее',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildAddStorageButton(context, isFullWidth: true),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isDesktop = maxWidth >= 600;

        if (!isDesktop) {
          return ListView.separated(
            padding: screenPadding,
            itemCount: storages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final storage = storages[index];
              final isSelected = selectedStorage?.path == storage.path;

              final isLastItem =
                  showCreateButton && index == storages.length - 1;
              if (isLastItem) {
                return Column(
                  children: [
                    StorageCard(
                      storage: storage,
                      isSelected: isSelected,
                      onTap: () => onStorageSelected(storage),
                      onDelete: onStorageDelete != null
                          ? () => onStorageDelete!(storage)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _buildAddStorageButton(context),
                  ],
                );
              }

              return StorageCard(
                storage: storage,
                isSelected: isSelected,
                onTap: () => onStorageSelected(storage),
                onDelete: onStorageDelete != null
                    ? () => onStorageDelete!(storage)
                    : null,
              );
            },
          );
        }

        final gridCount = _gridCrossAxisCount(maxWidth);

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: screenPadding,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                ),
                itemCount: storages.length,
                itemBuilder: (context, index) {
                  final storage = storages[index];
                  final isSelected = selectedStorage?.path == storage.path;

                  return StorageCard(
                    storage: storage,
                    isSelected: isSelected,
                    onTap: () => onStorageSelected(storage),
                    onDelete: onStorageDelete != null
                        ? () => onStorageDelete!(storage)
                        : null,
                  );
                },
              ),
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 12),
              Padding(
                padding: screenPadding,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildAddStorageButton(context, isFullWidth: true),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // build button to add new storage
  Widget _buildAddStorageButton(
    BuildContext context, {
    bool isFullWidth = true,
  }) {
    return SmoothButton(
      isFullWidth: isFullWidth,
      size: .large,
      label: 'Создать',
      onPressed: () => context.push(AppRoutesPaths.createStore),
      type: .dashed,
    );
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1600) return 4;
    if (width >= 1200) return 3;
    return 2;
  }
}
