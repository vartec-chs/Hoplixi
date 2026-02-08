import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/token_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/widgets/token_card.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Экран для просмотра всех активных OAuth токенов
class TokensScreen extends ConsumerWidget {
  const TokensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokensAsync = ref.watch(tokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Токены'),
        actions: [
          // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tokenProvider.notifier).reload();
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: tokensAsync.when(
        data: (tokens) {
          if (tokens.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(tokenProvider.notifier).reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: tokens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final token = tokens[index];
                return TokenCard(
                  token: token,
                  onDelete: () async {
                    await _handleDeleteToken(context, ref, token.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NotificationCard(
                    type: NotificationType.error,
                    text: error.toString(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(tokenProvider.notifier).reload();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vpn_key,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет активных токенов',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Здесь будут отображаться ваши OAuth токены для облачных сервисов',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteToken(
    BuildContext context,
    WidgetRef ref,
    String tokenId,
  ) async {
    try {
      // Удаляем токен через провайдер
      await ref.read(tokenProvider.notifier).deleteToken(tokenId);

      if (context.mounted) {
        Toaster.success(
          title: 'Токен удален',
          description: 'OAuth токен успешно удален',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка удаления',
          description: 'Не удалось удалить токен: $e',
        );
      }
    }
  }
}
