import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/dashboard_v2.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';

import '../providers/duplicate_passwords_analysis_provider.dart';

class DuplicatePasswordsScreen extends ConsumerStatefulWidget {
  const DuplicatePasswordsScreen({super.key});

  @override
  ConsumerState<DuplicatePasswordsScreen> createState() =>
      _DuplicatePasswordsScreenState();
}

class _DuplicatePasswordsScreenState
    extends ConsumerState<DuplicatePasswordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(duplicatePasswordsAnalysisProvider.notifier).analyze();
    });
  }

  void _retry() {
    ref.read(duplicatePasswordsAnalysisProvider.notifier).analyze();
  }

  Future<void> _openPasswordEdit(String id) async {
    await context.push(
      AppRoutesPaths.dashboardEntityEdit(EntityType.password, id),
    );
    if (!mounted) return;
    ref.read(duplicatePasswordsAnalysisProvider.notifier).analyze();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(duplicatePasswordsAnalysisProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _retry(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Одинаковые пароли'),
              actions: [
                IconButton(
                  tooltip: 'Повторить анализ',
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DuplicatePasswordsEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _DuplicatePasswordGroupCard(
                        groupIndex: index + 1,
                        group: group,
                        onOpenPasswordEdit: _openPasswordEdit,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemCount: groups.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                hasScrollBody: false,
                child: _DuplicatePasswordsErrorState(onRetry: _retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuplicatePasswordsEmptyState extends StatelessWidget {
  const _DuplicatePasswordsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Дубликаты не найдены',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Среди активных записей нет паролей с одинаковым значением.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuplicatePasswordsErrorState extends StatelessWidget {
  const _DuplicatePasswordsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Не удалось выполнить анализ',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuplicatePasswordGroupCard extends StatelessWidget {
  const _DuplicatePasswordGroupCard({
    required this.groupIndex,
    required this.group,
    required this.onOpenPasswordEdit,
  });

  final int groupIndex;
  final DuplicatePasswordGroupDto group;
  final ValueChanged<String> onOpenPasswordEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_copy, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Группа $groupIndex',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Badge.count(count: group.count),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${group.count} записи используют одинаковый пароль',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final password in group.items) ...[
              _DuplicatePasswordItemTile(
                password: password,
                onTap: () => onOpenPasswordEdit(password.id),
              ),
              if (password != group.items.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DuplicatePasswordItemTile extends StatelessWidget {
  const _DuplicatePasswordItemTile({
    required this.password,
    required this.onTap,
  });

  final PasswordCardDto password;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final login = password.email ?? password.login;
    final url = password.url;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
        title: Text(
          password.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _PasswordDuplicateSubtitle(login: login, url: url),
        trailing: const Icon(Icons.edit_outlined),
        onTap: onTap,
      ),
    );
  }
}

class _PasswordDuplicateSubtitle extends StatelessWidget {
  const _PasswordDuplicateSubtitle({required this.login, required this.url});

  final String? login;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (login != null && login!.trim().isNotEmpty) login!,
      if (url != null && url!.trim().isNotEmpty) url!,
    ];

    if (parts.isEmpty) {
      return Text(
        'Нажмите, чтобы открыть редактирование',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
