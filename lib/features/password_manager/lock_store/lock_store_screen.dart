import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LockStoreScreen extends ConsumerStatefulWidget {
  const LockStoreScreen({super.key});

  @override
  ConsumerState<LockStoreScreen> createState() => _LockStoreScreenState();
}

class _LockStoreScreenState extends ConsumerState<LockStoreScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hasSavedPassword = false;

  @override
  void initState() {
    super.initState();
    _checkSavedPassword();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedPassword() async {
    final dbState = ref.read(mainStoreProvider).value;
    if (dbState?.path == null) return;

    final historyService = await ref.read(dbHistoryProvider.future);
    final entry = await historyService.getByPath(dbState!.path!);

    if (entry != null && entry.savePassword && entry.password != null) {
      setState(() {
        _hasSavedPassword = true;
        _passwordController.text = entry.password!;
      });
    }
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty && !_hasSavedPassword) {
      Toaster.error(title: 'Ошибка', description: 'Введите пароль');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(mainStoreProvider.notifier)
          .unlockStore(_passwordController.text);

      if (success) {
        if (mounted) {
          context.go(AppRoutesPaths.dashboard);
        }
      } else {
        if (mounted) {
          Toaster.error(title: 'Ошибка', description: 'Неверный пароль');
        }
      }
    } catch (e) {
      logError('Error unlocking store: $e', tag: 'LockStoreScreen');
      if (mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Произошла ошибка при разблокировке',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goHome() async {
    ref.read(mainStoreProvider.notifier).resetState();
    context.go(AppRoutesPaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(mainStoreProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'В целях безопасности база данных заблокирована',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (dbState?.name != null)
                  Text(
                    dbState!.name!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (dbState?.path != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dbState!.path!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 32),
                if (!_hasSavedPassword)
                  TextField(
                    controller: _passwordController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Пароль',
                      hintText: 'Введите пароль для разблокировки',
                      prefixIcon: const Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => _unlock(),
                  ),
                if (_hasSavedPassword)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Используется сохраненный пароль',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SmoothButton(
                  label: 'Разблокировать',
                  onPressed: _unlock,
                  loading: _isLoading,
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.normal,
                  icon: const Icon(Icons.lock_open),
                ),
                const SizedBox(height: 16),
                SmoothButton(
                  label: 'Закрыть и выйти',
                  onPressed: _goHome,
                  type: SmoothButtonType.text,
                  variant: SmoothButtonVariant.normal,
                  icon: const Icon(Icons.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
