import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_cloud_import_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/services/store_password_attempt_limiter_service.dart';
import 'package:hoplixi/features/password_manager/open_store/widgets/cloud_import_body.dart';
import 'package:hoplixi/features/password_manager/open_store/widgets/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';

class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  final _attemptLimiter = getIt<StorePasswordAttemptLimiterService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    });
  }

  Future<void> _handleStorageSelected(OpenStoreState state) async {
    final storage = state.selectedStorage;
    if (storage == null) {
      return;
    }

    final status = await _attemptLimiter.getStatus(storage.path);
    if (!mounted) {
      return;
    }

    if (status.isBlocked) {
      ref.read(openStoreFormProvider.notifier).cancelSelection();
      Toaster.error(
        title: 'Хранилище временно заблокировано',
        description: _attemptLimiter.buildBlockedDescription(status),
      );
      return;
    }

    _showPasswordFormDialog(state);
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
      next.whenData((state) {
        if (state.selectedStorage != null &&
            previous?.value?.selectedStorage != state.selectedStorage) {
          unawaited(_handleStorageSelected(state));
        }
      });
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Открыть хранилище'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref
                  .read(titlebarStateProvider.notifier)
                  .setBackgroundTransparent(true);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutesPaths.home);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: asyncState.isLoading
                  ? null
                  : () async {
                      await notifier.loadStorages();
                      // Также обновим Cloud Sync, если он инициализирован
                      await ref
                          .read(openStoreCloudImportProvider.notifier)
                          .reloadCloudOptions();
                    },
              tooltip: 'Обновить список',
            ),
          ],
          bottom: const TabBar(
            splashBorderRadius: BorderRadius.all(Radius.circular(16)),

            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(text: 'Локальные', icon: Icon(Icons.storage_outlined)),
              Tab(text: 'Бэкапы', icon: Icon(Icons.backup_outlined)),
              Tab(
                text: 'Cloud Sync',
                icon: Icon(Icons.cloud_download_outlined),
              ),
            ],
          ),
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

    return Column(
      children: [
        if (state.error != null) _buildErrorBanner(context, state.error!),
        Expanded(
          child: TabBarView(
            children: [
              _buildLocalTab(context, state, notifier, regularStorages),
              _buildBackupsTab(context, state, notifier, backupStorages),
              _buildCloudSyncTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocalTab(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
    List<StorageInfo> regularStorages,
  ) {
    if (state.isLoading && regularStorages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (regularStorages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Локальных хранилищ не найдено',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте новое хранилище, чтобы начать работу.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StorageList(
      storages: regularStorages,
      selectedStorage: state.selectedStorage,
      onStorageSelected: notifier.selectStorage,
      onStorageDelete: (storage) => _handleDeleteStorage(storage, ref),
    );
  }

  Widget _buildBackupsTab(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
    List<StorageInfo> backupStorages,
  ) {
    if (state.isLoading && backupStorages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (backupStorages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.backup_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Резервных копий не найдено',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Здесь будут отображаться резервные копии ваших хранилищ.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StorageList(
      storages: backupStorages,
      selectedStorage: state.selectedStorage,
      onStorageSelected: notifier.selectStorage,
      onStorageDelete: (storage) => _handleDeleteBackup(storage, ref),
      showCreateButton: false,
    );
  }

  Widget _buildCloudSyncTab(BuildContext context) {
    final asyncCloudState = ref.watch(openStoreCloudImportProvider);

    return asyncCloudState.when(
      data: (cloudState) => CloudImportBody(state: cloudState),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Не удалось загрузить данные Cloud Sync',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
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
    context.go(AppRoutesPaths.home);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }
}
