import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';

class AppRoutesPaths {
  static const String splash = '/splash';
  static const String setup = '/setup';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String logs = '/logs';
  static const String componentShowcase = '/component-showcase';

  // Add other route paths as needed
  static const String createStore = '/create-store';
  static const String openStore = '/open-store';
  static const String lockStore = '/lock-store';
  static const String archiveStore = '/archive-store';
  static const String oauthApps = '/oauth-apps';
  static const String oauthTokens = '/oauth-tokens';
  static const String oauthLogin = '/oauth-login';

  /// Path для Dashboard
  static const String dashboard = '/dashboard';
  static const String dashboardEntities = '/dashboard/:entity';
  static const String dashboardEntitiesHistory =
      '/dashboard/:entity/history/:id';

  static String dashboardHistoryWithParams(EntityType entity, String id) =>
      '/dashboard/${entity.id}/history/$id';

  /// Entity edit with params
  static String dashboardEntityEdit(EntityType entity, String id) =>
      '/dashboard/${entity.id}/edit/$id';

  /// - notes
  static const String notes = '/dashboard/notes';
  static const String noteAdd = '/dashboard/notes/add';
  static const String noteEdit = '/dashboard/notes/edit/:id';
  static const String notesGraph = '/dashboard/notes/graph';

  /// - passwords
  static const String passwords = '/dashboard/passwords';
  static const String passwordAdd = '/dashboard/passwords/add';
  static const String passwordEdit = '/dashboard/passwords/edit/:id';
  static String passwordMigrate = '/dashboard/passwords/migrate';

  /// otps
  static const String otps = '/dashboard/otps';
  static const String otpAdd = '/dashboard/otps/add';
  static const String otpEdit = '/dashboard/otps/edit/:id';

  /// - bank cards
  static const String bankCards = '/dashboard/bank-cards';
  static const String bankCardAdd = '/dashboard/bank-cards/add';
  static const String bankCardEdit = '/dashboard/bank-cards/edit/:id';

  /// - files
  static const String files = '/dashboard/files';
  static const String fileAdd = '/dashboard/files/add';
  static const String fileEdit = '/dashboard/files/edit/:id';

  /// dashboard right panel
  /// - categories
  static const String categories = '/dashboard/categories';
  static const String categoryAdd = '/dashboard/categories/add';
  static const String categoryEdit = '/dashboard/categories/edit/:id';

  /// - tags
  static const String tags = '/dashboard/tags';
  static const String tagAdd = '/dashboard/tags/add';
  static const String tagEdit = '/dashboard/tags/edit/:id';

  /// - icons
  static const String icons = '/dashboard/icons';
  static const String iconAdd = '/dashboard/icons/add';
  static const String iconEdit = '/dashboard/icons/edit/:id';
}
