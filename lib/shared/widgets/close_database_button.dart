import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

enum CloseDatabaseButtonType { icon, smooth }

class CloseDatabaseButton extends ConsumerStatefulWidget {
  final CloseDatabaseButtonType type;

  const CloseDatabaseButton({
    super.key,
    this.type = CloseDatabaseButtonType.icon,
  });

  @override
  ConsumerState<CloseDatabaseButton> createState() =>
      _CloseDatabaseButtonState();
}

class _CloseDatabaseButtonState extends ConsumerState<CloseDatabaseButton> {
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainStoreProvider);
    final dbState = state.value;
    final isOpen = dbState?.isOpen ?? false;
    final isClosingSync = dbState?.isClosingSync ?? false;
    final isBusy = _isClosing || isClosingSync;

    if (!isOpen && !isBusy) {
      return const SizedBox.shrink();
    }

    if (widget.type == CloseDatabaseButtonType.icon) {
      return IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : const Icon(Icons.logout, size: 20),
        tooltip: isBusy ? 'Закрытие хранилища...' : 'Закрыть базу данных',
        onPressed: isBusy ? null : () => _closeDatabase(context),
      );
    } else {
      return SmoothButton(
        label: 'Закрыть БД',
        icon: const Icon(Icons.logout, size: 16),
        size: SmoothButtonSize.small,
        variant: SmoothButtonVariant.error,
        loading: isBusy,
        onPressed: isBusy ? null : () => _closeDatabase(context),
      );
    }
  }

  Future<void> _closeDatabase(BuildContext context) async {
    if (_isClosing) {
      return;
    }

    setState(() {
      _isClosing = true;
    });

    try {
      final success = await ref.read(mainStoreProvider.notifier).closeStore();
      if (!context.mounted || success) {
        return;
      }

      final errorMessage =
          ref.read(mainStoreProvider).value?.error?.message ??
          'Не удалось закрыть хранилище.';
      Toaster.error(title: 'Закрытие хранилища', description: errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }
}
