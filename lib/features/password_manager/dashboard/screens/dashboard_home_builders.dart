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
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Длительность анимации переключения состояний.
const kStatusSwitchDuration = Duration(milliseconds: 180);

// ─────────────────────────────────────────────────────────────────────────────
// Callbacks
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Builders
// ─────────────────────────────────────────────────────────────────────────────

/// Класс-помощник для построения виджетов дашборда.
class DashboardHomeBuilders {
  const DashboardHomeBuilders._();

  // ───────────────────────────────────────────────────────────────────────────
  // Content Sliver
  // ───────────────────────────────────────────────────────────────────────────

  /// Построение основного контентного слайвера.
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
    required VoidCallback onInvalidate,
  }) {
    final hasDisplayedItems = displayedItems.isNotEmpty;

    // Если есть элементы — показываем только список
    if (hasDisplayedItems) {
      return _buildAnimatedListOrGrid(
        context: context,
        ref: ref,
        entityType: entityType,
        viewMode: viewMode,
        state: asyncValue.value,
        displayedItems: displayedItems,
        listKey: listKey,
        gridKey: gridKey,
        callbacks: callbacks,
      );
    }

    // Определяем, какой статусный слайвер показывать
    final statusSliver = _resolveStatusSliver(
      context: context,
      asyncValue: asyncValue,
      entityType: entityType,
      isClearing: isClearing,
      onRetry: onInvalidate,
    );

    return SliverMainAxisGroup(
      slivers: [
        // Пустой анимированный список (для согласованности ключей)
        _buildAnimatedListOrGrid(
          context: context,
          ref: ref,
          entityType: entityType,
          viewMode: viewMode,
          state: asyncValue.value,
          displayedItems: displayedItems,
          listKey: listKey,
          gridKey: gridKey,
          callbacks: callbacks,
        ),
        SliverAnimatedSwitcher(
          duration: kStatusSwitchDuration,
          child: statusSliver,
        ),
      ],
    );
  }

  /// Определяет какой статусный слайвер показать.
  static Widget _resolveStatusSliver({
    required BuildContext context,
    required AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
    required EntityType entityType,
    required bool isClearing,
    required VoidCallback onRetry,
  }) {
    if (isClearing) {
      return const SliverToBoxAdapter(
        key: ValueKey('clearing'),
        child: SizedBox.shrink(),
      );
    }

    if (asyncValue.isLoading) {
      return const SliverFillRemaining(
        key: ValueKey('loading'),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (asyncValue.hasError) {
      return _buildErrorSliver(
        context: context,
        error: asyncValue.error!,
        onRetry: onRetry,
        key: const ValueKey('error'),
      );
    }

    final providerItems = asyncValue.value?.items ?? [];
    if (providerItems.isEmpty) {
      return _buildEmptyState(
        context: context,
        entityType: entityType,
        key: const ValueKey('empty'),
      );
    }

    // Данные есть в провайдере, но ещё не синхронизированы —
    // не показываем индикатор загрузки, а просто ждём следующий frame.
    // Это состояние мгновенное и не должно показывать спиннер.
    return const SliverToBoxAdapter(
      key: ValueKey('syncing'),
      child: SizedBox.shrink(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Animated List / Grid
  // ───────────────────────────────────────────────────────────────────────────

  /// Построение анимированного списка или сетки.
  static Widget _buildAnimatedListOrGrid({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required ViewMode viewMode,
    required DashboardListState<BaseCardDto>? state,
    required List<BaseCardDto> displayedItems,
    required GlobalKey<SliverAnimatedListState> listKey,
    required GlobalKey<SliverAnimatedGridState> gridKey,
    required DashboardCardCallbacks callbacks,
    Key? key,
  }) {
    final hasMore = state?.hasMore ?? false;
    final isLoadingMore = state?.isLoadingMore ?? false;

    final listSliver = viewMode == ViewMode.list
        ? _buildSliverAnimatedList(
            listKey: listKey,
            displayedItems: displayedItems,
            context: context,
            ref: ref,
            entityType: entityType,
            viewMode: viewMode,
            callbacks: callbacks,
          )
        : _buildSliverAnimatedGrid(
            gridKey: gridKey,
            displayedItems: displayedItems,
            context: context,
            ref: ref,
            entityType: entityType,
            viewMode: viewMode,
            callbacks: callbacks,
          );

    return SliverMainAxisGroup(
      key: key,
      slivers: [
        listSliver,
        _buildFooter(
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          hasDisplayedItems: displayedItems.isNotEmpty,
        ),
      ],
    );
  }

  static Widget _buildSliverAnimatedList({
    required GlobalKey<SliverAnimatedListState> listKey,
    required List<BaseCardDto> displayedItems,
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required ViewMode viewMode,
    required DashboardCardCallbacks callbacks,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverAnimatedList(
        key: listKey,
        initialItemCount: displayedItems.length,
        itemBuilder: (ctx, index, animation) {
          if (index >= displayedItems.length) return const SizedBox.shrink();
          return _buildItemTransition(
            context: ctx,
            ref: ref,
            item: displayedItems[index],
            animation: animation,
            viewMode: viewMode,
            entityType: entityType,
            callbacks: callbacks,
          );
        },
      ),
    );
  }

  static Widget _buildSliverAnimatedGrid({
    required GlobalKey<SliverAnimatedGridState> gridKey,
    required List<BaseCardDto> displayedItems,
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required ViewMode viewMode,
    required DashboardCardCallbacks callbacks,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverAnimatedGrid(
        key: gridKey,
        initialItemCount: displayedItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (ctx, index, animation) {
          if (index >= displayedItems.length) return const SizedBox.shrink();
          return _buildItemTransition(
            context: ctx,
            ref: ref,
            item: displayedItems[index],
            animation: animation,
            viewMode: viewMode,
            entityType: entityType,
            callbacks: callbacks,
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Item Transitions
  // ───────────────────────────────────────────────────────────────────────────

  /// Построение перехода для элемента (вставка).
  static Widget _buildItemTransition({
    required BuildContext context,
    required WidgetRef ref,
    required BaseCardDto item,
    required Animation<double> animation,
    required ViewMode viewMode,
    required EntityType entityType,
    required DashboardCardCallbacks callbacks,
  }) {
    final card = viewMode == ViewMode.list
        ? buildListCardFor(
            context: context,
            ref: ref,
            type: entityType,
            item: item,
            callbacks: callbacks,
          )
        : buildGridCardFor(
            context: context,
            ref: ref,
            type: entityType,
            item: item,
            callbacks: callbacks,
          );

    return FadeScaleTransition(
      animation: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: card,
        ),
      ),
    );
  }

  /// Построение удалённого элемента (для анимации удаления).
  static Widget buildRemovedItem({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType entityType,
    required BaseCardDto item,
    required Animation<double> animation,
    required ViewMode viewMode,
    required DashboardCardCallbacks callbacks,
  }) {
    final card = viewMode == ViewMode.list
        ? buildListCardFor(
            context: context,
            ref: ref,
            type: entityType,
            item: item,
            callbacks: callbacks,
            isDismissible: false,
          )
        : buildGridCardFor(
            context: context,
            ref: ref,
            type: entityType,
            item: item,
            callbacks: callbacks,
          );

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(sizeFactor: animation, child: card),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Footer & Status States
  // ───────────────────────────────────────────────────────────────────────────

  /// Построение футера списка.
  static Widget _buildFooter({
    required bool hasMore,
    required bool isLoadingMore,
    required bool hasDisplayedItems,
  }) {
    if (isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (!hasMore && hasDisplayedItems) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Больше нет данных',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox(height: 8));
  }

  /// Построение пустого состояния.
  static Widget _buildEmptyState({
    required BuildContext context,
    required EntityType entityType,
    Key? key,
  }) {
    return SliverFillRemaining(
      key: key,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(entityType.icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Нет данных', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Добавьте первый элемент',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Построение слайвера с ошибкой.
  static Widget _buildErrorSliver({
    required BuildContext context,
    required Object error,
    required VoidCallback onRetry,
    Key? key,
  }) {
    return SliverFillRemaining(
      key: key,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Card Builders
  // ───────────────────────────────────────────────────────────────────────────

  /// Построение карточки для списка.
  static Widget buildListCardFor({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType type,
    required BaseCardDto item,
    required DashboardCardCallbacks callbacks,
    bool isDismissible = true,
  }) {
    final noCorrectType = Text(
      'No correct type for $type',
      style: const TextStyle(color: Colors.red),
    );

    final location = GoRouterState.of(context).uri.toString();

    Widget card;
    switch (type) {
      case EntityType.password:
        if (item is! PasswordCardDto) return noCorrectType;
        card = PasswordListCard(
          password: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.password,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.password,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.note:
        if (item is! NoteCardDto) return noCorrectType;
        card = NoteListCard(
          note: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.note,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.note,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.bankCard:
        if (item is! BankCardCardDto) return noCorrectType;
        card = BankCardListCard(
          bankCard: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () => {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.bankCard,
                  item.id,
                ))
              {
                context.push(
                  AppRoutesPaths.dashboardHistoryWithParams(
                    EntityType.bankCard,
                    item.id,
                  ),
                ),
              },
          },
        );
        break;
      case EntityType.file:
        if (item is! FileCardDto) return noCorrectType;
        card = FileListCard(
          file: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onDecrypt: () => showFileDecryptModal(context, item),
          onOpenHistory: () => {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.file,
                  item.id,
                ))
              {
                context.push(
                  AppRoutesPaths.dashboardHistoryWithParams(
                    EntityType.file,
                    item.id,
                  ),
                ),
              },
          },
        );
        break;
      case EntityType.otp:
        if (item is! OtpCardDto) return noCorrectType;
        card = TotpListCard(
          otp: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () => {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.otp,
                  item.id,
                ))
              {
                context.push(
                  AppRoutesPaths.dashboardHistoryWithParams(
                    EntityType.otp,
                    item.id,
                  ),
                ),
              },
          },
        );
        break;
      case EntityType.document:
        if (item is! DocumentCardDto) return noCorrectType;
        card = DocumentListCard(
          document: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onDecrypt: () => showDocumentDecryptModal(context, item),
          onOpenHistory: () => {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.document,
                  item.id,
                ))
              {
                context.push(
                  AppRoutesPaths.dashboardHistoryWithParams(
                    EntityType.document,
                    item.id,
                  ),
                ),
              },
          },
        );
        break;
      case EntityType.apiKey:
        if (item is! ApiKeyCardDto) return noCorrectType;
        card = ApiKeyListCard(
          apiKey: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.apiKey,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.apiKey,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.contact:
        if (item is! ContactCardDto) return noCorrectType;
        card = ContactListCard(
          contact: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
        break;
      case EntityType.sshKey:
        if (item is! SshKeyCardDto) return noCorrectType;
        card = SshKeyListCard(
          sshKey: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.sshKey,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.sshKey,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.certificate:
        if (item is! CertificateCardDto) return noCorrectType;
        card = CertificateListCard(
          certificate: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.certificate,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.certificate,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.cryptoWallet:
        if (item is! CryptoWalletCardDto) return noCorrectType;
        card = CryptoWalletListCard(
          wallet: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.cryptoWallet,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.cryptoWallet,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.wifi:
        if (item is! WifiCardDto) return noCorrectType;
        card = WifiListCard(
          wifi: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.wifi,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.wifi,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.identity:
        if (item is! IdentityCardDto) return noCorrectType;
        card = IdentityListCard(
          identity: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.identity,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.identity,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.licenseKey:
        if (item is! LicenseKeyCardDto) return noCorrectType;
        card = LicenseKeyListCard(
          license: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.licenseKey,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.licenseKey,
                  item.id,
                ),
              );
            }
          },
        );
        break;
      case EntityType.recoveryCodes:
        if (item is! RecoveryCodesCardDto) return noCorrectType;
        card = RecoveryCodesListCard(
          recoveryCodes: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onOpenHistory: () {
            if (location !=
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.recoveryCodes,
                  item.id,
                )) {
              context.push(
                AppRoutesPaths.dashboardHistoryWithParams(
                  EntityType.recoveryCodes,
                  item.id,
                ),
              );
            }
          },
        );
        break;
    }

    // Обертка для долгого нажатия -> открытие view
    final wrappedCard = GestureDetector(
      onLongPress: () {
        final viewPath = AppRoutesPaths.dashboardEntityView(type, item.id);
        if (GoRouter.of(context).state.matchedLocation != viewPath) {
          context.push(viewPath);
        }
      },
      child: card,
    );

    if (!isDismissible) return wrappedCard;

    return buildDismissible(
      context: context,
      ref: ref,
      child: wrappedCard,
      item: item,
      type: type,
      callbacks: callbacks,
    );
  }

  /// Обертка в Dismissible виджет
  static Widget buildDismissible({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
    required BaseCardDto item,
    required EntityType type,
    required DashboardCardCallbacks callbacks,
  }) {
    final isDeleted = item.isDeleted;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: isDeleted
              ? Colors.greenAccent
              : (item.isArchived ? Colors.orangeAccent : Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: Icon(
          isDeleted
              ? Icons.restore
              : (item.isArchived ? Icons.unarchive : Icons.edit),
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Вправо → редактирование, восстановление или разархивирование
          if (isDeleted) {
            // Восстанавливаем удаленный элемент
            callbacks.onRestore(item.id);
            return false;
          } else if (item.isArchived) {
            // Разархивируем элемент
            callbacks.onToggleArchive(item.id);
            return false;
          }

          // Открываем экран редактирования для не удаленных и не архивированных элементов
          if (item is PasswordCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.password,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is BankCardCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.bankCard,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is NoteCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.note,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is OtpCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.otp,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is FileCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.file,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is DocumentCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.document,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is ApiKeyCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.apiKey,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is ContactCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.contact,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is SshKeyCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.sshKey,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is CertificateCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.certificate,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is CryptoWalletCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.cryptoWallet,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is WifiCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.wifi,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is IdentityCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.identity,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is LicenseKeyCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.licenseKey,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          } else if (item is RecoveryCodesCardDto) {
            final path = AppRoutesPaths.dashboardEntityEdit(
              EntityType.recoveryCodes,
              item.id,
            );
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          }

          return false;
        } else {
          // Влево → удаление
          String itemName = 'неизвестный элемент';
          if (item is PasswordCardDto) {
            itemName = item.name;
          } else if (item is BankCardCardDto) {
            itemName = item.name;
          } else if (item is NoteCardDto) {
            itemName = item.title;
          } else if (item is OtpCardDto) {
            itemName = item.accountName ?? 'OTP';
          } else if (item is FileCardDto) {
            itemName = item.name;
          } else if (item is DocumentCardDto) {
            itemName = item.title ?? 'Документ';
          } else if (item is ApiKeyCardDto) {
            itemName = item.name;
          } else if (item is ContactCardDto) {
            itemName = item.name;
          } else if (item is SshKeyCardDto) {
            itemName = item.name;
          } else if (item is CertificateCardDto) {
            itemName = item.name;
          } else if (item is CryptoWalletCardDto) {
            itemName = item.name;
          } else if (item is WifiCardDto) {
            itemName = item.name;
          } else if (item is IdentityCardDto) {
            itemName = item.name;
          } else if (item is LicenseKeyCardDto) {
            itemName = item.name;
          } else if (item is RecoveryCodesCardDto) {
            itemName = item.name;
          }

          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text("Удалить?"),
              content: Text("Вы уверены, что хотите удалить '$itemName'?"),
              actions: [
                SmoothButton(
                  type: SmoothButtonType.text,
                  onPressed: () => Navigator.pop(dialogContext, false),
                  label: "Отмена",
                ),
                SmoothButton(
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.error,
                  onPressed: () => Navigator.pop(dialogContext, true),
                  label: "Удалить",
                ),
              ],
            ),
          );
          return shouldDelete ?? false;
        }
      },
      onDismissed: (_) {
        // Сначала удаляем локально без анимации, чтобы Dismissible не жаловался
        callbacks.onLocalRemove(item.id);
        // Затем удаляем через провайдер
        callbacks.onDelete(item.id, item.isDeleted);
      },
      child: child,
    );
  }

  /// Построение карточки для сетки
  static Widget buildGridCardFor({
    required BuildContext context,
    required WidgetRef ref,
    required EntityType type,
    required BaseCardDto item,
    required DashboardCardCallbacks callbacks,
  }) {
    final noCorrectType = Text(
      'No correct type for $type',
      style: const TextStyle(color: Colors.red),
    );

    Widget card;
    switch (type) {
      case EntityType.password:
        if (item is! PasswordCardDto) return noCorrectType;
        card = PasswordGridCard(
          password: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.note:
        if (item is! NoteCardDto) return noCorrectType;
        card = NoteGridCard(
          note: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.bankCard:
        if (item is! BankCardCardDto) return noCorrectType;
        card = BankCardGridCard(
          bankCard: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.file:
        if (item is! FileCardDto) return noCorrectType;
        card = FileGridCard(
          file: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onDecrypt: () => showFileDecryptModal(context, item),
        );
      case EntityType.otp:
        if (item is! OtpCardDto) return noCorrectType;
        card = TotpGridCard(
          otp: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.document:
        if (item is! DocumentCardDto) return noCorrectType;
        card = DocumentGridCard(
          document: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
          onDecrypt: () => showDocumentDecryptModal(context, item),
        );
      case EntityType.apiKey:
        if (item is! ApiKeyCardDto) return noCorrectType;
        card = ApiKeyGridCard(
          apiKey: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.contact:
        if (item is! ContactCardDto) return noCorrectType;
        card = ContactGridCard(
          contact: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.sshKey:
        if (item is! SshKeyCardDto) return noCorrectType;
        card = SshKeyGridCard(
          sshKey: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.certificate:
        if (item is! CertificateCardDto) return noCorrectType;
        card = CertificateGridCard(
          certificate: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.cryptoWallet:
        if (item is! CryptoWalletCardDto) return noCorrectType;
        card = CryptoWalletGridCard(
          wallet: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.wifi:
        if (item is! WifiCardDto) return noCorrectType;
        card = WifiGridCard(
          wifi: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.identity:
        if (item is! IdentityCardDto) return noCorrectType;
        card = IdentityGridCard(
          identity: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.licenseKey:
        if (item is! LicenseKeyCardDto) return noCorrectType;
        card = LicenseKeyGridCard(
          license: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.recoveryCodes:
        if (item is! RecoveryCodesCardDto) return noCorrectType;
        card = RecoveryCodesGridCard(
          recoveryCodes: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
    }

    // Обёртка для долгого нажатия -> открытие view
    return GestureDetector(
      onLongPress: () {
        final viewPath = AppRoutesPaths.dashboardEntityView(type, item.id);
        if (GoRouter.of(context).state.matchedLocation != viewPath) {
          context.push(viewPath);
        }
      },
      child: card,
    );
  }
}
