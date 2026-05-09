import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/about/screens/about_licenses_screen.dart';
import 'package:hoplixi/features/archive_storage/ui/archive_screen.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/screens/app_credentials_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/screens/auth_progress_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/screens/auth_tokens_screen.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/screens/cloud_sync_playground_screen.dart';
import 'package:hoplixi/features/cloud_sync/screens/cloud_sync_storage_screen.dart';
import 'package:hoplixi/features/component_showcase/component_showcase_screen.dart';
import 'package:hoplixi/features/custom_icon_packs/screens/icon_packs_screen.dart';
import 'package:hoplixi/features/home/crypt_test_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/local_send/screens/local_send_history_screen.dart';
import 'package:hoplixi/features/local_send/screens/local_send_screen.dart';
import 'package:hoplixi/features/local_send/screens/local_send_transfer_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/features/password_manager/close_store/close_store_sync_screen.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/dashboard_v2.dart';
import 'package:hoplixi/features/password_manager/duplicate_passwords/screen/duplicate_passwords_screen.dart';
import 'package:hoplixi/features/password_manager/forms/entity_add_edit.dart';
import 'package:hoplixi/features/password_manager/forms/entity_view.dart';
import 'package:hoplixi/features/password_manager/history/ui/screens/history_screen.dart';
import 'package:hoplixi/features/password_manager/import/keepass/screens/keepass_import_screen.dart';
import 'package:hoplixi/features/password_manager/import/otp/screens/import_otp_screen.dart';
import 'package:hoplixi/features/password_manager/import/passwords/screens/password_migration_screen.dart';
import 'package:hoplixi/features/password_manager/lock_store/lock_store_screen.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/screens/category_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/screens/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/managers/icon_manager/icon_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/icon_manager/icon_manager_screen.dart';
import 'package:hoplixi/features/password_manager/managers/tags_manager/tag_form_screen.dart';
import 'package:hoplixi/features/password_manager/managers/tags_manager/tags_manager_screen.dart';
import 'package:hoplixi/features/password_manager/notes_graph/notes_graph_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_cloud_import_screen.dart';
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
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPage<void>(key: state.pageKey, child: child);
    }

    return MaterialPage<void>(key: state.pageKey, child: child);
  }

  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final String _dashboardEntityRoutePattern =
    '/dashboard/:entity(${EntityType.values.map((t) => t.id).join('|')})';

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
    path: AppRoutesPaths.aboutLicenses,
    builder: (context, state) => const AboutLicensesScreen(),
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
    path: AppRoutesPaths.localSendTransfer,
    builder: (context, state) => const LocalSendTransferScreen(),
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
    path: AppRoutesPaths.openStoreCloudImport,
    builder: (context, state) => const OpenStoreCloudImportScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.lockStore,
    builder: (context, state) => const LockStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.closeStoreSync,
    builder: (context, state) => const CloseStoreSyncScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.archiveStore,
    builder: (context, state) => const ArchiveScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.iconPacks,
    builder: (context, state) => const IconPacksScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.cloudSync,
    builder: (context, state) => const CloudSyncPlaygroundScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.cloudSyncStorage,
    builder: (context, state) => CloudSyncStorageScreen(
      initialProvider: _parseCloudSyncProvider(
        state.uri.queryParameters['provider'],
      ),
    ),
  ),
  GoRoute(
    path: AppRoutesPaths.cloudSyncAppCredentials,
    builder: (context, state) => const AppCredentialsScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.cloudSyncAuthTokens,
    builder: (context, state) => const AuthTokensScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.cloudSyncAuthProgress,
    builder: (context, state) => const AuthProgressScreen(),
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
        path: AppRoutesPaths.keepassImport,
        pageBuilder: (context, state) {
          return buildResponsivePage(
            context: context,
            state: state,
            child: const KeepassImportScreen(),
          );
        },
      ),
      GoRoute(
        path: _dashboardEntityRoutePattern,
        name: 'entity',
        pageBuilder: (context, state) {
          final entity = EntityType.fromId(state.pathParameters['entity']!)!;
          return buildResponsivePage(
            context: context,
            state: state,
            isBaseRoute: true,
            child: DashboardV2HomeScreen(
              initialEntityType: EntityType.fromId(entity.id)!,
            ),
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
              return buildResponsivePage(
                context: context,
                state: state,
                child: const NotesGraphScreen(),
              );
            },
          ),
          GoRoute(
            path: 'duplicates',
            name: 'entity_password_duplicates',
            redirect: (context, state) {
              final ent = state.pathParameters['entity'];
              if (ent != EntityType.password.id) return '/dashboard/$ent';
              return null;
            },
            pageBuilder: (context, state) {
              return buildResponsivePage(
                context: context,
                state: state,
                child: const DuplicatePasswordsScreen(),
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
            path: 'import',
            name: 'entity_import',
            redirect: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              if (entity != EntityType.password && entity != EntityType.otp) {
                return '/dashboard/${entity.id}';
              }
              return null;
            },
            pageBuilder: (context, state) {
              final entity = EntityType.fromId(
                state.pathParameters['entity']!,
              )!;
              return buildResponsivePage(
                context: context,
                state: state,
                child: entity == EntityType.otp
                    ? const ImportOtpScreen()
                    : const PasswordMigrationScreen(),
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

CloudSyncProvider? _parseCloudSyncProvider(String? rawValue) {
  if (rawValue == null || rawValue.trim().isEmpty) {
    return null;
  }

  final normalized = rawValue.trim().toLowerCase();
  for (final provider in CloudSyncProvider.values) {
    if (provider.id == normalized) {
      return provider;
    }
  }

  return null;
}
