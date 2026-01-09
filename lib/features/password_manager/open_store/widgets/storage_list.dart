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

  const StorageList({
    super.key,
    required this.storages,
    required this.selectedStorage,
    required this.onStorageSelected,
    this.onStorageDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (storages.isEmpty) {
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
              _buildAddStorageButton(context),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: screenPadding,
      itemCount: storages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final storage = storages[index];
        final isSelected = selectedStorage?.path == storage.path;

        final isLastItem = index == storages.length - 1;
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

  // build button to add new storage
  Widget _buildAddStorageButton(BuildContext context) {
    return SmoothButton(
      isFullWidth: true,
      size: .large,
      label: 'Создать',
      onPressed: () => context.push(AppRoutesPaths.createStore),
      type: .dashed,
    );
  }
}
