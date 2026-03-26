import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/widgets/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';

class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    });
  }

  void _showPasswordFormDialog(OpenStoreState state) {
    final notifier = ref.read(openStoreFormProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: !state.isOpening,
        builder: (dialogContext) => Dialog(
          insetPadding: EdgeInsets.all(screenPaddingValue),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: PasswordForm(
              onSuccess: () => _handleOpenSuccess(dialogContext),
              onCancel: () {
                Navigator.of(dialogContext).pop();
                notifier.cancelSelection();
              },
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !state.isOpening,
      enableDrag: !state.isOpening,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: PasswordForm(
          onSuccess: () => _handleOpenSuccess(sheetContext),
          onCancel: () {
            Navigator.of(sheetContext).pop();
            notifier.cancelSelection();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(openStoreFormProvider);
    final notifier = ref.read(openStoreFormProvider.notifier);

    ref.listen<AsyncValue<OpenStoreState>>(openStoreFormProvider, (
      previous,
      next,
    ) {
      next.whenData((state) async {
        if (state.selectedStorage != null &&
            previous?.value?.selectedStorage != state.selectedStorage) {
          _showPasswordFormDialog(state);
        }

        final pendingBinding = state.pendingImportedStoreBinding;
        final previousBinding = previous?.value?.pendingImportedStoreBinding;
        if (pendingBinding == null ||
            identical(pendingBinding, previousBinding)) {
          return;
        }

        final shouldBind = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Привязать к cloud sync'),
            content: Text(pendingBinding.promptDescription),
            actions: [
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                label: 'Нет',
                type: SmoothButtonType.text,
              ),
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: 'Привязать',
              ),
            ],
          ),
        );

        if (!mounted) {
          return;
        }

        final didBind = await notifier.resolvePendingImportedStoreBinding(
          bind: shouldBind == true,
        );
        if (!mounted) {
          return;
        }

        if (didBind) {
          Toaster.success(
            context: context,
            title: 'Cloud Sync',
            description: 'Локальная копия привязана к облачному store.',
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Открыть хранилище'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref
                .read(titlebarStateProvider.notifier)
                .setBackgroundTransparent(true);
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: asyncState.isLoading
                ? null
                : () async => notifier.loadStorages(),
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _buildBody(context, state, notifier),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Инициализация...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка инициализации',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SmoothButton(
                onPressed: () => ref.invalidate(openStoreFormProvider),
                icon: const Icon(Icons.refresh),
                label: 'Повторить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
  ) {
    final regularStorages = state.storages
        .where((storage) => !storage.path.contains('_backup_'))
        .toList(growable: false);
    final backupStorages = state.storages
        .where((storage) => storage.path.contains('_backup_'))
        .toList(growable: false);

    if (state.isLoading && state.storages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка хранилищ...'),
          ],
        ),
      );
    }

    if (state.error != null && state.storages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SmoothButton(
              onPressed: () => notifier.loadStorages(),
              icon: const Icon(Icons.refresh),
              label: 'Повторить',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.error != null) _buildErrorBanner(context, state.error!),
        _buildCloudImportEntry(context),
        const Divider(height: 1),
        Expanded(
          child: backupStorages.isEmpty
              ? StorageList(
                  storages: regularStorages,
                  selectedStorage: state.selectedStorage,
                  onStorageSelected: notifier.selectStorage,
                  onStorageDelete: (storage) =>
                      _handleDeleteStorage(storage, ref),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StorageList(
                        storages: regularStorages,
                        selectedStorage: state.selectedStorage,
                        onStorageSelected: notifier.selectStorage,
                        onStorageDelete: (storage) =>
                            _handleDeleteStorage(storage, ref),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Бэкапы',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: StorageList(
                              storages: backupStorages,
                              selectedStorage: state.selectedStorage,
                              onStorageSelected: notifier.selectStorage,
                              onStorageDelete: (storage) =>
                                  _handleDeleteBackup(storage, ref),
                              showCreateButton: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCloudImportEntry(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.cloud_download_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Скачать snapshot из Cloud Sync',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Откройте отдельный экран, чтобы выбрать провайдера, OAuth токен и скачать удалённое хранилище в локальную папку.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SmoothButton(
                      onPressed: () =>
                          context.push(AppRoutesPaths.openStoreCloudImport),
                      icon: const Icon(Icons.arrow_forward_outlined),
                      label: 'Открыть импорт из облака',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteStorage(StorageInfo storage, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить хранилище'),
        content: Text(
          'Удалить хранилище "${storage.name}" с диска?\n\n'
          'Это действие необратимо! Все данные будут удалены безвозвратно.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final notifier = ref.read(openStoreFormProvider.notifier);
    final success = await notifier.deleteStorage(storage.path);
    if (!mounted) {
      return;
    }

    if (success) {
      Toaster.success(
        context: context,
        title: 'Успех',
        description: 'Хранилище удалено с диска',
      );
      return;
    }

    Toaster.error(
      context: context,
      title: 'Ошибка',
      description: 'Не удалось удалить хранилище',
    );
  }

  Future<void> _handleDeleteBackup(StorageInfo storage, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить бэкап'),
        content: Text(
          'Удалить бэкап "${storage.name}" с диска?\n\n'
          'Это действие необратимо.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final notifier = ref.read(openStoreFormProvider.notifier);
    final success = await notifier.deleteStorage(storage.path);
    if (!mounted) {
      return;
    }

    if (success) {
      Toaster.success(
        context: context,
        title: 'Успех',
        description: 'Бэкап удалён с диска',
      );
      return;
    }

    Toaster.error(
      context: context,
      title: 'Ошибка',
      description: 'Не удалось удалить бэкап',
    );
  }

  void _handleOpenSuccess(BuildContext dialogContext) {
    if (!mounted) {
      return;
    }

    Navigator.of(dialogContext).pop();
    Toaster.success(
      context: context,
      title: 'Успешно',
      description: 'Хранилище открыто',
    );
    context.go(AppRoutesPaths.home);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }
}
