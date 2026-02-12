import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';

class AppRoutesPaths {
  static const String splash = '/splash';
  static const String setup = '/setup';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String logs = '/logs';
  static const String componentShowcase = '/component-showcase';

  /// LocalSend — экран отправки файлов по локальной сети.
  static const String localSendSend = '/localsend/send';

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

  /// Entity view with params
  static String dashboardEntityView(EntityType entity, String id) =>
      '/dashboard/${entity.id}/view/$id';

  /// Dashboard entity view route pattern
  static const String dashboardEntitiesView = '/dashboard/:entity/view/:id';

  /// - notes
  static const String notes = '/dashboard/notes';
  static const String noteAdd = '/dashboard/notes/add';
  static const String noteEdit = '/dashboard/notes/edit/:id';
  static const String notesGraph = '/dashboard/notes/graph';

  /// - passwords
  static String passwords = '/dashboard/${EntityType.password.id}';
  static String passwordAdd = '/dashboard/${EntityType.password.id}/add';
  static String passwordEdit = '/dashboard/${EntityType.password.id}/edit/:id';
  static String passwordMigrate =
      '/dashboard/${EntityType.password.id}/migrate';

  /// otps
  static String otps = '/dashboard/${EntityType.otp.id}';
  static String otpAdd = '/dashboard/${EntityType.otp.id}/add';
  static String otpEdit = '/dashboard/${EntityType.otp.id}/edit/:id';
  static String otpImport = '/dashboard/${EntityType.otp.id}/import';

  /// - bank cards
  static String bankCards = '/dashboard/${EntityType.bankCard.id}';
  static String bankCardAdd = '/dashboard/${EntityType.bankCard.id}/add';
  static String bankCardEdit = '/dashboard/${EntityType.bankCard.id}/edit/:id';

  /// - files
  static String files = '/dashboard/${EntityType.file.id}';
  static String fileAdd = '/dashboard/${EntityType.file.id}/add';
  static String fileEdit = '/dashboard/${EntityType.file.id}/edit/:id';

  /// - documents
  static String documents = '/dashboard/${EntityType.document.id}';
  static String documentAdd = '/dashboard/${EntityType.document.id}/add';
  static String documentEdit = '/dashboard/${EntityType.document.id}/edit/:id';

  static String categoryEditWithId(EntityType entity, String id) =>
      '/dashboard/${entity.id}/categories/edit/$id';

  static String categoryAdd(EntityType entity) =>
      '/dashboard/${entity.id}/categories/add';

  /// - tags
  static const String tags = '/dashboard/tags';
  static const String tagAdd = '/dashboard/tags/add';
  static const String tagEdit = '/dashboard/tags/edit/:id';

  static String tagsAdd(EntityType entity) =>
      '/dashboard/${entity.id}/tags/add';
  static String tagsEdit(EntityType entity, String id) =>
      '/dashboard/${entity.id}/tags/edit/$id';

  /// - icons
  static const String icons = '/dashboard/icons';
  static const String iconAdd = '/dashboard/icons/add';
  static const String iconEdit = '/dashboard/icons/edit/:id';

  static String iconAddForEntity(EntityType entity) =>
      '/dashboard/${entity.id}/icons/add';

  static String iconEditForEntity(EntityType entity, String id) =>
      '/dashboard/${entity.id}/icons/edit/$id';
  static String iconEditWithId(String id) => '/dashboard/icons/edit/$id';
}
