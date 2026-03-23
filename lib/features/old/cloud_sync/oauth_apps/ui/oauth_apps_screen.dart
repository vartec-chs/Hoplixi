import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/providers/oauth_apps_provider.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/ui/widgets/oauth_app_card.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/ui/widgets/oauth_app_modal.dart';
import 'package:hoplixi/routing/paths.dart';

/// Экран для управления OAuth приложениями
class OAuthAppsScreen extends ConsumerWidget {
  const OAuthAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(oauthAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth приложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(oauthAppsProvider.notifier).reload();
            },
            tooltip: 'Обновить список',
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: () {
              context.push(AppRoutesPaths.oauthTokens);
            },
            tooltip: 'Токены OAuth',
          ),

          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              context.push(AppRoutesPaths.oauthLogin);
            },
            tooltip: 'Вход OAuth',
          ),
        ],
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(oauthAppsProvider.notifier).reload();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет OAuth приложений',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Создайте первое приложение',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      _showCreateAppModal(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Создать приложение'),
                  ),
                ],
              ),
            );
          }

          // Разделяем встроенные и пользовательские приложения
          final builtinApps = apps.where((app) => app.isBuiltin).toList();
          final customApps = apps.where((app) => !app.isBuiltin).toList();

          return CustomScrollView(
            slivers: [
              if (builtinApps.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Встроенные приложения',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final app = builtinApps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OAuthAppCard(
                          app: app,
                          onTap: null, // Встроенные нельзя редактировать
                          onDelete: null, // Встроенные нельзя удалять
                          isBuiltin: true,
                        ),
                      );
                    }, childCount: builtinApps.length),
                  ),
                ),
              ],
              if (customApps.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Пользовательские приложения',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final app = customApps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OAuthAppCard(
                          app: app,
                          onTap: () => _showEditAppModal(context, app),
                          onDelete: () => _confirmDelete(context, ref, app),
                        ),
                      );
                    }, childCount: customApps.length),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateAppModal(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  void _showCreateAppModal(BuildContext context) {
    showOAuthAppModal(context: context);
  }

  void _showEditAppModal(BuildContext context, OauthApps app) {
    showOAuthAppModal(context: context, app: app);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    OauthApps app,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить приложение?'),
        content: Text(
          'Вы уверены, что хотите удалить приложение "${app.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(oauthAppsProvider.notifier).deleteApp(app.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Приложение "${app.name}" удалено')),
        );
      }
    }
  }
}
