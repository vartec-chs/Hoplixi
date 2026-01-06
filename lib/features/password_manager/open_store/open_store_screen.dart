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

/// Экран открытия хранилища
class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTitleBarLabel();
    });
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
  }

  void _showPasswordFormDialog(OpenStoreState state) {
    final notifier = ref.read(openStoreFormProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      // Показать диалог на больших экранах
      showDialog(
        context: context,
        barrierDismissible: !state.isOpening,
        builder: (dialogContext) => Dialog(
          insetPadding: EdgeInsets.all(screenPaddingValue),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              // color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
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
    } else {
      // Показать bottom sheet на мобильных
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
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(openStoreFormProvider);
    final notifier = ref.read(openStoreFormProvider.notifier);

    // Отслеживаем изменения состояния
    ref.listen<AsyncValue<OpenStoreState>>(openStoreFormProvider, (
      previous,
      next,
    ) {
      next.whenData((state) {
        // Если хранилище было выбрано
        if (state.selectedStorage != null &&
            previous?.value?.selectedStorage != state.selectedStorage) {
          _showPasswordFormDialog(state);
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
                : () => notifier.loadStorages(),
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _buildBody(context, state, notifier, ref),
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
        error: (error, stack) => Center(
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
                label: "Повторить",
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
    WidgetRef ref,
  ) {
    // Показываем индикатор загрузки
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

    // Показываем ошибку если есть
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
              label: "Повторить",
            ),
          ],
        ),
      );
    }

    // Показываем список хранилищ
    return Column(
      children: [
        if (state.error != null)
          Container(
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
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed: () {
                    // Очистить ошибку через новый метод если добавите
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: StorageList(
            storages: state.storages,
            selectedStorage: state.selectedStorage,
            onStorageSelected: notifier.selectStorage,
          ),
        ),
      ],
    );
  }

  void _handleOpenSuccess(BuildContext dialogContext) {
    if (!mounted) return;

    // Закрыть модальное окно
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
