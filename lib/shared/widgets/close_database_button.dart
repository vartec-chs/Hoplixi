import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

enum CloseDatabaseButtonType { icon, smooth }

class CloseDatabaseButton extends ConsumerWidget {
  final CloseDatabaseButtonType type;

  const CloseDatabaseButton({
    super.key,
    this.type = CloseDatabaseButtonType.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainStoreProvider);
    final isOpen = state.value?.isOpen ?? false;

    if (!isOpen) {
      return const SizedBox.shrink();
    }

    if (type == CloseDatabaseButtonType.icon) {
      return IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
        icon: const Icon(Icons.logout, size: 20),
        tooltip: 'Закрыть базу данных',
        onPressed: () => _closeDatabase(context, ref),
      );
    } else {
      return SmoothButton(
        label: 'Закрыть БД',
        icon: const Icon(Icons.logout, size: 16),
        size: SmoothButtonSize.small,
        variant: SmoothButtonVariant.error,
        onPressed: () => _closeDatabase(context, ref),
      );
    }
  }

  Future<void> _closeDatabase(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(mainStoreProvider.notifier).closeStore();
    if (!context.mounted || success) {
      return;
    }

    final errorMessage =
        ref.read(mainStoreProvider).value?.error?.message ??
        'Не удалось закрыть хранилище.';
    Toaster.error(title: 'Закрытие хранилища', description: errorMessage);
  }
}
