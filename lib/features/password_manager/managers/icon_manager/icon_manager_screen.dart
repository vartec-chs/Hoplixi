import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/old/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

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

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700.0;
  }

  void _refresh() {
    final notifier = ref.read(iconListProvider.notifier);
    notifier.refresh();
  }

  void _openEdit(String iconId) {
    context
        .push<bool>(AppRoutesPaths.iconEditForEntity(widget.entity, iconId))
        .then((updated) {
          if (updated == true) {
            _refresh();
          }
        });
  }

  Future<void> _handleDeleteIcon(BuildContext context, IconsData icon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить иконку?'),
        content: Text('Вы уверены, что хотите удалить иконку "${icon.name}"?'),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            variant: SmoothButtonVariant.error,
            label: 'Удалить',
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      await iconDao.deleteIcon(icon.id);

      ref.read(managerRefreshTriggerProvider.notifier).triggerIconRefresh();
      _refresh();

      if (context.mounted) {
        Toaster.success(
          title: 'Иконка удалена',
          description: 'Иконка "${icon.name}" успешно удалена.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка удаления',
          description:
              'Не удалось удалить иконку "${icon.name}". Попробуйте еще раз.',
        );
      }
    }
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
            onIconTap: (icon) => _openEdit(icon.id),
            onIconLongPress: (icon) => _handleDeleteIcon(context, icon),
          ),
        ],
      ),
      floatingActionButton: _isMobileLayout(context)
          ? FloatingActionButton(
              heroTag: 'iconManagerFab',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
            )
          : null,
    );
  }
}
