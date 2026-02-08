import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';

import '../dashboard_layout_constants.dart';

/// Утилита для построения FAB действий в DashboardLayout.
///
/// Инкапсулирует логику создания FAB actions и навигации.
class DashboardFabBuilder {
  final BuildContext context;
  final String entity;
  final String? currentAction;
  final bool isMobile;

  const DashboardFabBuilder({
    required this.context,
    required this.entity,
    required this.currentAction,
    required this.isMobile,
  });

  /// Построить список действий FAB для текущей entity.
  List<FABActionData> buildFabActions() {
    final theme = Theme.of(context);

    // Если на странице categories/tags/icons, первым действием — добавить элемент
    FABActionData? primaryAction;
    if (currentAction == 'categories') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить категорию',
        onPressed: () => _onFabActionPressed('add_category'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else if (currentAction == 'tags') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить тег',
        onPressed: () => _onFabActionPressed('add_tag'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else if (currentAction == 'icons') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить иконку',
        onPressed: () => _onFabActionPressed('add_icon'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    }

    final actions = <FABActionData>[];
    if (primaryAction != null) {
      actions.add(primaryAction);
    } else {
      // Стандартные действия для главной страницы entity
      actions.add(
        FABActionData(
          icon: Icons.add,
          label: 'Добавить',
          onPressed: () => _onFabActionPressed('add'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    // Остальные действия
    actions.addAll([
      FABActionData(
        icon: Icons.category,
        label: 'Категории',
        onPressed: () => _onFabActionPressed('categories'),
      ),
      FABActionData(
        icon: Icons.tag,
        label: 'Теги',
        onPressed: () => _onFabActionPressed('tags'),
      ),
      FABActionData(
        icon: Icons.image,
        label: 'Иконки',
        onPressed: () => _onFabActionPressed('icons'),
      ),
    ]);

    return actions;
  }

  /// Обработать нажатие на FAB action.
  void _onFabActionPressed(String action) {
    final entityType = EntityType.fromId(entity)!;
    String path;

    switch (action) {
      case 'add':
        path = '/dashboard/$entity/add';
        break;
      case 'add_category':
        path = AppRoutesPaths.categoryAdd(entityType);
        break;
      case 'add_tag':
        path = AppRoutesPaths.tagsAdd(entityType);
        break;
      case 'add_icon':
        path = AppRoutesPaths.iconAddForEntity(entityType);
        break;
      case 'categories':
        path = '/dashboard/$entity/categories';
        break;
      case 'tags':
        path = '/dashboard/$entity/tags';
        break;
      case 'icons':
        path = '/dashboard/$entity/icons';
        break;
      default:
        path = '/dashboard/$entity/$action';
    }

    if (context.mounted) {
      context.go(path);
    }
  }

  /// Построить ExpandableFAB виджет.
  Widget buildExpandableFAB() {
    return ExpandableFAB(
      executeFirstActionDirectly: true,
      direction: isMobile
          ? FABExpandDirection.up
          : FABExpandDirection.rightDown,
      isUseInNavigationRail: !isMobile,
      shape: isMobile ? FABShape.circle : FABShape.square,
      actions: buildFabActions(),
    );
  }
}
