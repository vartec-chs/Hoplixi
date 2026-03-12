import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/archive_storage/ui/archive_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/auth_login_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/tokens_screen.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/ui/oauth_apps_screen.dart';
import 'package:hoplixi/features/component_showcase/component_showcase_screen.dart';
import 'package:hoplixi/features/home/crypt_test_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/local_send/screens/local_send_history_screen.dart';
import 'package:hoplixi/features/local_send/screens/local_send_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/notes_graph_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_add_edit.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_view.dart';
import 'package:hoplixi/features/password_manager/history/ui/screens/history_screen.dart';
import 'package:hoplixi/features/password_manager/lock_store/lock_store_screen.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/screens/category_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/screens/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/managers/icon_manager/icon_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/icon_manager/icon_manager_screen.dart';
import 'package:hoplixi/features/password_manager/managers/tags_manager/tag_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/tags_manager/tags_manager_screen.dart';
import 'package:hoplixi/features/password_manager/migration/otp/screens/import_otp_screen.dart';
import 'package:hoplixi/features/password_manager/migration/passwords/screens/password_migration_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_screen.dart';
import 'package:hoplixi/features/settings/screens/settings_screen.dart';
import 'package:hoplixi/features/setup/screens/setup_screen.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/routing/paths.dart';

Page<void> buildResponsivePage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool isBaseRoute = false,
}) {
  final isMobile =
      MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;

  if (isMobile) {
    if (isBaseRoute) {
      return NoTransitionPage<void>(key: state.pageKey, child: child);
    }

    return MaterialPage<void>(key: state.pageKey, child: child);
  }

  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutesPaths.splash,
    builder: (context, state) => const BaseScreen(title: 'Splash Screen'),
  ),
  GoRoute(
    path: AppRoutesPaths.setup,
    builder: (context, state) => const SetupScreen(),
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
    path: AppRoutesPaths.localSendSend,
    builder: (context, state) => const LocalSendScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.localSendHistory,
    builder: (context, state) => const LocalSendHistoryScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.cryptTest,
    builder: (context, state) => const CryptTestScreen(),
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
    redirect: (context, state) => '/dashboard/${EntityType.password.id}',
  ),
  ShellRoute(
    navigatorKey: dashboardNavigatorKey,
    builder: (context, state, child) {
      return AppNavigationShell(state: state, child: child);
    },
    routes: [
      GoRoute(
        path: '/dashboard/:entity',
        name: 'entity',
        pageBuilder: (context, state) {
          final entity = EntityType.fromId(state.pathParameters['entity']!)!;
          return buildResponsivePage(
            context: context,
            state: state,
            isBaseRoute: true,
            child: DashboardHomeScreen(entityType: entity),
          );
        },
        routes: [
          GoRoute(
            path: 'categories',
            name: 'entity_categories',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: CategoryManagerScreen(entity: entity),
              );
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'entity_categories_add',
                pageBuilder: (context, state) {
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: CategoryFormScreen(forEntity: entity),
                  );
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'entity_categories_edit',
                pageBuilder: (context, state) {
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  final id = state.pathParameters['id']!;
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: CategoryFormScreen(
                      forEntity: entity,
                      categoryId: id,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'tags',
            name: 'entity_tags',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: TagsManagerScreen(entity: entity),
              );
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'entity_tags_add',
                pageBuilder: (context, state) {
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: TagFormScreen(entityType: entity),
                  );
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'entity_tags_edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final entity = EntityType.fromId(
                    state.pathParameters['entity']!,
                  )!;
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: TagFormScreen(tagId: id, entityType: entity),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'icons',
            name: 'entity_icons',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: IconManagerScreen(entity: entity),
              );
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'entity_icons_add',
                pageBuilder: (context, state) {
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: const IconFormScreen(),
                  );
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'entity_icons_edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return buildResponsivePage(
                    context: context,
                    state: state,
                    child: IconFormScreen(iconId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'add',
            name: 'entity_add',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: EntityAddEdit(entity: entity, isEdit: false),
              );
            },
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'entity_edit',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              final id = state.pathParameters['id']!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: EntityAddEdit(entity: entity, isEdit: true, id: id),
              );
            },
          ),
          GoRoute(
            path: 'view/:id',
            name: 'entity_view',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              final id = state.pathParameters['id']!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: EntityView(entity: entity, id: id),
              );
            },
          ),
          GoRoute(
            path: 'graph',
            name: 'entity_notes_graph',
            redirect: (context, state) {
              final ent = state.pathParameters['entity'];
              if (ent != 'notes') return '/dashboard/$ent';
              return null;
            },
            pageBuilder: (context, state) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: const NotesGraphScreen(),
              );
            },
          ),
          GoRoute(
            path: 'history/:id',
            name: 'entity_history',
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              final id = state.pathParameters['id']!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: HistoryScreen(entityType: entity, entityId: id),
              );
            },
          ),
          GoRoute(
            path: 'migrate',
            name: 'entity_migrate',
            redirect: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              if (entity != EntityType.password) {
                return '/dashboard/${entity.id}';
              }
              return null;
            },
            pageBuilder: (context, state) {
              return buildResponsivePage(
                context: context,
                state: state,
                child: const PasswordMigrationScreen(),
              );
            },
          ),
          GoRoute(
            path: 'import',
            name: 'entity_import',
            redirect: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              if (entity != EntityType.otp) {
                return '/dashboard/${entity.id}';
              }
              return null;
            },
            pageBuilder: (context, state) {
              return buildResponsivePage(
                context: context,
                state: state,
                child: const ImportOtpScreen(),
              );
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
