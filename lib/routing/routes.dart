import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/archive_storage/ui/archive_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/auth_login_screen.dart';
import 'package:hoplixi/features/cloud_sync/auth/ui/tokens_screen.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/ui/oauth_apps_screen.dart';
import 'package:hoplixi/features/component_showcase/component_showcase_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/features/password_manager/category_manager/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/categories_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_settings_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/notes_graph_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/search_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/forms/bank_card_form/screens/bank_card_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/file_form/screens/file_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/screens/note_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/screens/otp_form_screen.dart';
import 'package:hoplixi/features/password_manager/forms/password_form/screens/password_form_screen.dart';
import 'package:hoplixi/features/password_manager/history/ui/screens/history_screen.dart';
import 'package:hoplixi/features/password_manager/icon_manager/icon_manager_screen.dart';
import 'package:hoplixi/features/password_manager/lock_store/lock_store_screen.dart';
import 'package:hoplixi/features/password_manager/migration/otp/screens/import_otp_screen.dart';
import 'package:hoplixi/features/password_manager/migration/passwords/screens/password_migration_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_manager_screen.dart';
import 'package:hoplixi/features/settings/screens/settings_screen.dart';
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

  // Dashboard с вложенными роутами через ShellRoute
  ShellRoute(
    builder: (context, state, child) => DashboardLayout(child: child),
    routes: [
      GoRoute(
        path: AppRoutesPaths.dashboardHome,
        builder: (context, state) {
          return const DashboardHomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardCategories,
        builder: (context, state) {
          return const CategoriesScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardSearch,
        builder: (context, state) {
          return const SearchScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardSettings,
        builder: (context, state) {
          return const DashboardSettingsScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardIconManager,
        builder: (context, state) {
          return const IconManagerScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardCategoryManager,
        builder: (context, state) {
          return const CategoryManagerScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardTagManager,
        builder: (context, state) {
          return const TagsManagerScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardMigration,
        builder: (context, state) {
          return const PasswordMigrationScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardNotesGraph,
        builder: (context, state) {
          return const NotesGraphScreen();
        },
      ),

      // Password forms
      GoRoute(
        path: AppRoutesPaths.dashboardPasswordCreate,
        pageBuilder: (context, state) {
          return const MaterialPage(
            key: ValueKey('password_create'),
            child: PasswordFormScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardPasswordEdit,
        builder: (context, state) {
          final passwordId = state.pathParameters['id'];
          return PasswordFormScreen(passwordId: passwordId);
        },
      ),

      // Note forms
      GoRoute(
        path: AppRoutesPaths.dashboardNoteCreate,
        builder: (context, state) {
          return const NoteFormScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardNoteEdit,
        builder: (context, state) {
          final noteId = state.pathParameters['id'];
          return NoteFormScreen(noteId: noteId);
        },
      ),

      // Bank Card forms
      GoRoute(
        path: AppRoutesPaths.dashboardBankCardCreate,
        builder: (context, state) {
          return const BankCardFormScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardBankCardEdit,
        builder: (context, state) {
          final bankCardId = state.pathParameters['id'];
          return BankCardFormScreen(bankCardId: bankCardId);
        },
      ),

      // File forms
      GoRoute(
        path: AppRoutesPaths.dashboardFileCreate,
        builder: (context, state) {
          return const FileFormScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardFileEdit,
        builder: (context, state) {
          final fileId = state.pathParameters['id'];
          return FileFormScreen(fileId: fileId);
        },
      ),

      // OTP forms
      GoRoute(
        path: AppRoutesPaths.dashboardOtpCreate,
        builder: (context, state) {
          return const OtpFormScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardMigrateOtp,
        builder: (context, state) {
          return const ImportOtpScreen();
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardOtpEdit,
        builder: (context, state) {
          final otpId = state.pathParameters['id'];
          return OtpFormScreen(otpId: otpId);
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardMigratePasswords,
        builder: (context, state) {
          return const PasswordMigrationScreen();
        },
      ),

      // History screen
      GoRoute(
        path: AppRoutesPaths.dashboardHistory,
        pageBuilder: (context, state) {
          final entityTypeStr = state.pathParameters['entityType'];
          final entityId = state.pathParameters['id'];

          // Парсим тип сущности
          final entityType = EntityType.fromId(entityTypeStr ?? '');

          if (entityType == null || entityId == null) {
            // Если параметры некорректны, возвращаем на главную
            return const MaterialPage(child: DashboardHomeScreen());
          }

          // Используем уникальный ключ на основе параметров маршрута
          // чтобы избежать конфликтов GlobalKey при push-навигации
          return MaterialPage(
            key: ValueKey('history_${entityTypeStr}_$entityId'),
            child: HistoryScreen(entityType: entityType, entityId: entityId),
          );
        },
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
