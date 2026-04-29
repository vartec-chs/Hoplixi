import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/api_key/api_key_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/api_key/api_key_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/bank_card/bank_card_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/bank_card/bank_card_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/certificate/certificate_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/certificate/certificate_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/contact/contact_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/contact/contact_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/crypto_wallet/crypto_wallet_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/crypto_wallet/crypto_wallet_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/document/document_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/document/document_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/file/file_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/file/file_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/identity/identity_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/identity/identity_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/license_key/license_key_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/license_key/license_key_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/loyalty_card/loyalty_card_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/loyalty_card/loyalty_card_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/note/note_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/note/note_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/otp/otp_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/otp/otp_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password/password_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password/password_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/recovery_codes/recovery_codes_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/recovery_codes/recovery_codes_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/ssh_key/ssh_key_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/ssh_key/ssh_key_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/wifi/wifi_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/wifi/wifi_list_card.dart';
import 'package:hoplixi/features/password_manager/decrypt_modal/document_decrypt_modal.dart';
import 'package:hoplixi/features/password_manager/decrypt_modal/file_decrypt_modal.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:sliver_tools/sliver_tools.dart';

part 'dashboard_home_builders/animated_slivers.dart';
part 'dashboard_home_builders/card_builders.dart';
part 'dashboard_home_builders/content_sliver.dart';
part 'dashboard_home_builders/item_transitions.dart';
part 'dashboard_home_builders/status_slivers.dart';

/// Длительность анимации переключения состояний.
const kStatusSwitchDuration = Duration(milliseconds: 180);

/// Коллбэки для действий с элементами списка.
class DashboardCardCallbacks {
  const DashboardCardCallbacks({
    required this.onToggleFavorite,
    required this.onTogglePin,
    required this.onToggleArchive,
    required this.onDelete,
    required this.onRestore,
    required this.onLocalRemove,
  });

  final void Function(String id) onToggleFavorite;
  final void Function(String id) onTogglePin;
  final void Function(String id) onToggleArchive;
  final void Function(String id, bool? isDeleted) onDelete;
  final void Function(String id) onRestore;
  final void Function(String id) onLocalRemove;

  /// Создаёт коллбэки из [WidgetRef] с локальным удалением.
  factory DashboardCardCallbacks.fromRefWithLocalRemove(
    WidgetRef ref,
    EntityType entityType,
    void Function(String id) onLocalRemove,
  ) {
    final notifier = ref.read(paginatedListProvider(entityType).notifier);
    return DashboardCardCallbacks(
      onToggleFavorite: notifier.toggleFavorite,
      onTogglePin: notifier.togglePin,
      onToggleArchive: notifier.toggleArchive,
      onDelete: (id, isDeleted) {
        if (isDeleted == true) {
          notifier.permanentDelete(id);
        } else {
          notifier.delete(id);
        }
      },
      onRestore: notifier.restoreFromDeleted,
      onLocalRemove: onLocalRemove,
    );
  }
}

/// Класс-помощник для построения виджетов дашборда.
class DashboardHomeBuilders {
  const DashboardHomeBuilders._();

  static Widget buildContentSliver({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required ViewMode viewMode,
    required AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
    required List<BaseCardDto> displayedItems,
    required bool isClearing,
    required GlobalKey<SliverAnimatedListState> listKey,
    required GlobalKey<SliverAnimatedGridState> gridKey,
    required DashboardCardCallbacks callbacks,
    required bool isBulkMode,
    required Set<String> selectedIds,
    required void Function(String id) onItemTap,
    required void Function(String id) onItemLongPress,
    required void Function(String id) onOpenView,
    required VoidCallback onInvalidate,
  }) => _buildDashboardContentSliver(
    context: context,
    ref: ref,
    entityType: entityType,
    viewMode: viewMode,
    asyncValue: asyncValue,
    displayedItems: displayedItems,
    isClearing: isClearing,
    listKey: listKey,
    gridKey: gridKey,
    callbacks: callbacks,
    isBulkMode: isBulkMode,
    selectedIds: selectedIds,
    onItemTap: onItemTap,
    onItemLongPress: onItemLongPress,
    onOpenView: onOpenView,
    onInvalidate: onInvalidate,
  );

  static Widget buildRemovedItem({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required BaseCardDto item,
    required Animation<double> animation,
    required ViewMode viewMode,
    required DashboardCardCallbacks callbacks,
  }) => _buildDashboardRemovedItem(
    context: context,
    ref: ref,
    entityType: entityType,
    item: item,
    animation: animation,
    viewMode: viewMode,
    callbacks: callbacks,
  );

  static Widget buildListCardFor({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType type,
    required BaseCardDto item,
    required DashboardCardCallbacks callbacks,
    required bool isBulkMode,
    required bool isSelected,
    required void Function(String id) onItemTap,
    required void Function(String id) onItemLongPress,
    required void Function(String id) onOpenView,
    bool isDismissible = true,
  }) => _buildDashboardListCardFor(
    context: context,
    ref: ref,
    type: type,
    item: item,
    callbacks: callbacks,
    isBulkMode: isBulkMode,
    isSelected: isSelected,
    onItemTap: onItemTap,
    onItemLongPress: onItemLongPress,
    onOpenView: onOpenView,
    isDismissible: isDismissible,
  );

  static Widget buildDismissible({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
    required BaseCardDto item,
    required EntityType type,
    required DashboardCardCallbacks callbacks,
  }) => _buildDashboardDismissible(
    context: context,
    ref: ref,
    child: child,
    item: item,
    type: type,
    callbacks: callbacks,
  );

  static Widget buildGridCardFor({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType type,
    required BaseCardDto item,
    required DashboardCardCallbacks callbacks,
    required bool isBulkMode,
    required bool isSelected,
    required void Function(String id) onItemTap,
    required void Function(String id) onItemLongPress,
    required void Function(String id) onOpenView,
  }) => _buildDashboardGridCardFor(
    context: context,
    ref: ref,
    type: type,
    item: item,
    callbacks: callbacks,
    isBulkMode: isBulkMode,
    isSelected: isSelected,
    onItemTap: onItemTap,
    onItemLongPress: onItemLongPress,
    onOpenView: onOpenView,
  );
}
