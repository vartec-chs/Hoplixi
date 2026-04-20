part of '../dashboard_home_screen.dart';

Future<void> _dashboardHomeShowBulkDeleteDialog(
  _DashboardHomeScreenState state,
) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  final selectedItems = state._selectedItems;
  final isPermanentDelete =
      selectedItems.isNotEmpty && selectedItems.every((item) => item.isDeleted);

  final shouldDelete = await showDialog<bool>(
    context: state.context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          isPermanentDelete ? 'Удалить навсегда?' : 'Удалить элементы?',
        ),
        content: Text(
          isPermanentDelete
              ? 'Будет безвозвратно удалено элементов: ${selectedItems.length}.'
              : 'Будет перемещено в удалённые элементов: ${selectedItems.length}.',
        ),
        actions: [
          SmoothButton(
            type: SmoothButtonType.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Отмена',
          ),
          SmoothButton(
            variant: SmoothButtonVariant.error,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: isPermanentDelete ? 'Удалить навсегда' : 'Удалить',
          ),
        ],
      );
    },
  );

  if (shouldDelete != true) {
    return;
  }

  await state._runBulkAction(
    action: (notifier, ids) =>
        notifier.bulkDelete(ids, permanently: isPermanentDelete),
    successTitle: isPermanentDelete
        ? 'Элементы удалены навсегда'
        : 'Элементы перемещены в удалённые',
  );
}

Future<void> _dashboardHomeShowBulkAssignCategoryDialog(
  _DashboardHomeScreenState state,
) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  String? selectedCategoryId;
  String? selectedCategoryName;

  final confirmed = await showDialog<bool>(
    context: state.context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Назначить категорию'),
            content: SizedBox(
              height: 54,
              child: CategoryPickerField(
                selectedCategoryId: selectedCategoryId,
                selectedCategoryName: selectedCategoryName,
                filterByType: [
                  state.widget.entityType.toCategoryType(),
                  CategoryType.mixed,
                ],
                onCategorySelected: (categoryId, categoryName) {
                  setDialogState(() {
                    selectedCategoryId = categoryId;
                    selectedCategoryName = categoryName;
                  });
                },
              ),
            ),
            actions: [
              SmoothButton(
                type: SmoothButtonType.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                label: 'Отмена',
              ),
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: 'Применить',
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  await state._runBulkAction(
    action: (notifier, ids) =>
        notifier.bulkAssignCategory(ids, selectedCategoryId),
    successTitle: selectedCategoryId == null
        ? 'Категория очищена'
        : 'Категория назначена',
  );
}

Future<void> _dashboardHomeShowBulkAssignTagsDialog(
  _DashboardHomeScreenState state,
) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  List<String> selectedTagIds = <String>[];
  List<String> selectedTagNames = <String>[];

  final confirmed = await showDialog<bool>(
    context: state.context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Назначить теги'),
            content: SizedBox(
              height: 54,
              child: TagPickerField(
                selectedTagIds: selectedTagIds,
                selectedTagNames: selectedTagNames,
                filterByType: [
                  state.widget.entityType.toTagType(),
                  TagType.mixed,
                ],
                onTagsSelected: (tagIds, tagNames) {
                  setDialogState(() {
                    selectedTagIds = List<String>.from(tagIds);
                    selectedTagNames = List<String>.from(tagNames);
                  });
                },
              ),
            ),
            actions: [
              SmoothButton(
                type: SmoothButtonType.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                label: 'Отмена',
              ),
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: 'Применить',
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  await state._runBulkAction(
    action: (notifier, ids) => notifier.bulkAssignTags(ids, selectedTagIds),
    successTitle: selectedTagIds.isEmpty ? 'Теги очищены' : 'Теги обновлены',
  );
}

Future<bool> _dashboardHomeCloseDatabase(
  _DashboardHomeScreenState state,
) async {
  final success = await state.ref.read(mainStoreProvider.notifier).closeStore();
  if (success) {
    return true;
  }

  if (state.mounted) {
    final errorMessage =
        state.ref.read(mainStoreProvider).value?.error?.message ??
        'Не удалось закрыть хранилище.';
    Toaster.error(title: 'Закрытие хранилища', description: errorMessage);
  }
  return false;
}

Future<bool> _dashboardHomeCloseDatabaseWithOverlay(
  _DashboardHomeScreenState state,
) async {
  final rootNavigator = Navigator.of(state.context, rootNavigator: true);
  var isOverlayVisible = true;

  unawaited(
    showDialog<void>(
      context: state.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _CloseStoreProgressOverlay(),
    ).whenComplete(() {
      isOverlayVisible = false;
    }),
  );

  try {
    return await _dashboardHomeCloseDatabase(state);
  } finally {
    if (isOverlayVisible && rootNavigator.mounted) {
      rootNavigator.pop();
    }
  }
}

class _CloseStoreProgressOverlay extends StatelessWidget {
  const _CloseStoreProgressOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black45,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 14),
                    Text(
                      'Закрываем хранилище...',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Если синхронизация подключена, сначала проверим статус.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _dashboardHomeShowCloseDatabaseDialog(_DashboardHomeScreenState state) {
  showDialog(
    context: state.context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Закрыть базу данных?'),
        content: const Text('Вы уверены, что хотите закрыть базу данных?'),
        actions: <Widget>[
          SmoothButton(
            label: 'Нет',
            onPressed: () {
              Navigator.of(context).pop();
            },
            variant: .normal,
            size: .small,
            type: .text,
          ),
          SmoothButton(
            label: 'Да',
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _dashboardHomeCloseDatabaseWithOverlay(
                state,
              );
              if (success && state.mounted) {
                state.context.go(AppRoutesPaths.home);
              }
            },
            variant: .error,
            size: .small,
          ),
        ],
      );
    },
  );
}
