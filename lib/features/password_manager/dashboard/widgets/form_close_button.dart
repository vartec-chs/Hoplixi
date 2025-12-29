import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/routing/paths.dart';

class FormCloseButton extends ConsumerWidget {
  const FormCloseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
      tooltip: 'Закрыть',
      icon: context.canPop()
          ? const Icon(Icons.arrow_back, size: 24)
          : const Icon(Icons.close, size: 24),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutesPaths.dashboard);
        }
      },
    );
  }
}
