import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/routing/paths.dart';

import 'provider/icon_list_provider.dart';
import 'widgets/icon_list_view.dart';
import 'widgets/icon_manager_app_bar.dart';

/// Экран управления иконками с фильтрацией и пагинацией
class IconManagerScreen extends ConsumerStatefulWidget {
  const IconManagerScreen({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<IconManagerScreen> createState() => _IconManagerScreenState();
}

class _IconManagerScreenState extends ConsumerState<IconManagerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    final notifier = ref.read(iconListProvider.notifier);
    notifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const IconManagerAppBar(),
          IconListView(
            scrollController: _scrollController,
            onRefresh: _refresh,
            onIconTap: (icon) {
              final result = context.push<bool>(
                AppRoutesPaths.iconEditForEntity(widget.entity, icon.id),
              );

              result.then((updated) {
                if (updated == true) {
                  _refresh();
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'iconManagerFab',
        onPressed: () {
          final result = context.push<bool>(
            AppRoutesPaths.iconAddForEntity(widget.entity),
          );

          result.then((added) {
            if (added == true) {
              _refresh();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Виджет для отображения строки информации
class _InfoRow extends ConsumerWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
