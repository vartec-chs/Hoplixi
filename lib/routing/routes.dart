import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/archive_storage/ui/archive_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/auth_login_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/tokens_screen.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/ui/oauth_apps_screen.dart';
import 'package:hoplixi/features/component_showcase/component_showcase_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/features/password_manager/category_manager/screens/category_form_screen.dart';
import 'package:hoplixi/features/password_manager/category_manager/screens/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/notes_graph_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_add_edit.dart';
import 'package:hoplixi/features/password_manager/history/ui/screens/history_screen.dart';
import 'package:hoplixi/features/password_manager/icon_manager/icon_manager_screen.dart';
import 'package:hoplixi/features/password_manager/lock_store/lock_store_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_manager_screen.dart';
import 'package:hoplixi/features/settings/screens/settings_screen.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/routing/paths.dart';

final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutesPaths.splash,
    builder: (context, state) => const BaseScreen(title: 'Splash Screen'),
  ),
  GoRoute(
    path: AppRoutesPaths.home,
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.logs,
    builder: (context, state) => const LogsTabsScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.componentShowcase,
    builder: (context, state) => const ComponentShowcaseScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.createStore,
    builder: (context, state) => const CreateStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.openStore,
    builder: (context, state) => const OpenStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.lockStore,
    builder: (context, state) => const LockStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.archiveStore,
    builder: (context, state) => const ArchiveScreen(),
  ),

  GoRoute(
    path: AppRoutesPaths.settings,
    builder: (context, state) => const SettingsScreen(),
  ),

  GoRoute(
    path: AppRoutesPaths.oauthApps,
    builder: (context, state) => const OAuthAppsScreen(),
  ),

  GoRoute(
    path: AppRoutesPaths.oauthTokens,
    builder: (context, state) => const TokensScreen(),
  ),

  GoRoute(
    path: AppRoutesPaths.oauthLogin,
    builder: (context, state) => const OAuthLoginScreen(),
  ),

  GoRoute(
    path: '/dashboard',
    redirect: (context, state) => '/dashboard/passwords',
  ),

  ShellRoute(
    navigatorKey: dashboardNavigatorKey,
    builder: (context, state, child) {
      // child — самый глубокий совпавший маршрут (если есть) — используем в DashboardLayout
      return DashboardLayout(state: state, panelChild: child);
    },
    routes: [
      GoRoute(
        path: '/dashboard/:entity',
        name: 'entity',
        // Здесь не возвращаем содержимое центра — оно рендерится в DashboardLayout (IndexedStack + inner Navigators).
        // Этот GoRoute существует для сопоставления базовой сущности и для вложенных panel маршрутов.
        builder: (context, state) => const SizedBox.shrink(),
        routes: [
          // categories + nested add/edit
          GoRoute(
            path: 'categories',
            name: 'entity_categories',
            builder: (context, state) {
              // final entity = state.pathParameters['entity']!;
              return const CategoryManagerScreen();
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'entity_categories_add',
                builder: (context, state) {
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  return CategoryFormScreen(forEntity: entity);
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'entity_categories_edit',
                builder: (context, state) {
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  final id = state.pathParameters['id']!;
                  return CategoryFormScreen(forEntity: entity, categoryId: id);
                },
              ),
            ],
          ),

          // tags + add/edit
          GoRoute(
            path: 'tags',
            name: 'entity_tags',
            builder: (context, state) {
              // final entity = state.pathParameters['entity']!;
              return const TagsManagerScreen();
            },
            routes: [
              // GoRoute(
              //   path: 'add',
              //   name: 'entity_tags_add',
              //   builder: (context, state) {
              //     final entity = state.pathParameters['entity']!;
              //     return TagAddEditPanel(forEntity: entity, isEdit: false);
              //   },
              // ),
              // GoRoute(
              //   path: 'edit/:id',
              //   name: 'entity_tags_edit',
              //   builder: (context, state) {
              //     final entity = state.pathParameters['entity']!;
              //     final id = state.pathParameters['id']!;
              //     return TagAddEditPanel(
              //       forEntity: entity,
              //       isEdit: true,
              //       id: id,
              //     );
              //   },
              // ),
            ],
          ),

          // icons + add/edit
          GoRoute(
            path: 'icons',
            name: 'entity_icons',
            builder: (context, state) {
              // final entity = state.pathParameters['entity']!;
              return const IconManagerScreen();
            },
            routes: [
              // GoRoute(
              //   path: 'add',
              //   name: 'entity_icons_add',
              //   builder: (context, state) {
              //     final entity = state.pathParameters['entity']!;
              //     return IconAddEditPanel(forEntity: entity, isEdit: false);
              //   },
              // ),
              // GoRoute(
              //   path: 'edit/:id',
              //   name: 'entity_icons_edit',
              //   builder: (context, state) {
              //     final entity = state.pathParameters['entity']!;
              //     final id = state.pathParameters['id']!;
              //     return IconAddEditPanel(
              //       forEntity: entity,
              //       isEdit: true,
              //       id: id,
              //     );
              //   },
              // ),
            ],
          ),

          // add/edit для основной сущности
          GoRoute(
            path: 'add',
            name: 'entity_add',
            builder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return EntityAddEdit(entity: entity, isEdit: false);
            },
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'entity_edit',
            builder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              final id = state.pathParameters['id']!;
              return EntityAddEdit(entity: entity, isEdit: true, id: id);
            },
          ),

          GoRoute(
            path: 'graph', // -> /dashboard/:entity/notesGraph
            name: 'entity_notes_graph',
            redirect: (context, state) {
              final ent = state.pathParameters['entity'];
              // Разрешаем только для notes — для других сущностей редиректим на /dashboard/:entity
              if (ent != 'notes') return '/dashboard/$ent';
              return null;
            },
            builder: (context, state) {
              // final ent = state.pathParameters['entity']!;
              return const NotesGraphScreen();
            },
          ),

          /// histoyry/:id
          GoRoute(
            path: 'history/:id',
            name: 'entity_history',
            builder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              final id = state.pathParameters['id']!;
              return HistoryScreen(entityType: entity, entityId: id);
            },
          ),
        ],
      ),
    ],
  ),
];

class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title ?? 'Base Screen')));
  }
}
