import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/bank_card/bank_card_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/bank_card/bank_card_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/file/file_grid_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/file/file_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/note/note_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/note/note_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/otp/otp_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/otp/otp_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password/password_grid.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password/password_list_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/modals/file_decrypt_modal.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:sliver_tools/sliver_tools.dart';

const kStatusSwitchDuration = Duration(milliseconds: 180);

/// Коллбэки для действий с элементами списка
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

  /// Создать коллбэки из WidgetRef с локальным удалением
  factory DashboardCardCallbacks.fromRefWithLocalRemove(
    WidgetRef ref,
    EntityType entityType,
    void Function(String id) onLocalRemove,
  ) {
    return DashboardCardCallbacks(
      onToggleFavorite: (id) => ref
          .read(paginatedListProvider(entityType).notifier)
          .toggleFavorite(id),
      onTogglePin: (id) =>
          ref.read(paginatedListProvider(entityType).notifier).togglePin(id),
      onToggleArchive: (id) => ref
          .read(paginatedListProvider(entityType).notifier)
          .toggleArchive(id),
      onDelete: (id, isDeleted) {
        if (isDeleted == true) {
          ref
              .read(paginatedListProvider(entityType).notifier)
              .permanentDelete(id);
        } else {
          ref.read(paginatedListProvider(entityType).notifier).delete(id);
        }
      },
      onRestore: (id) => ref
          .read(paginatedListProvider(entityType).notifier)
          .restoreFromDeleted(id),
      onLocalRemove: onLocalRemove,
    );
  }
}

/// Класс-помощник для построения виджетов дашборда
class DashboardHomeBuilders {
  const DashboardHomeBuilders._();

  /// Построение основного контентного слайвера
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
    final hasItems = displayedItems.isNotEmpty;

    if (hasItems) {
      return buildAnimatedListOrGrid(
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

    final providerHasItems = asyncValue.value?.items.isNotEmpty ?? false;
    final isInitialLoading = asyncValue.isLoading && !hasItems;
    final isError = asyncValue.hasError && !hasItems;
    final showStatus = !hasItems && !isClearing;

    Widget? statusSliver;
    if (showStatus) {
      if (isInitialLoading) {
        statusSliver = const SliverFillRemaining(
          key: ValueKey('loading'),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (isError) {
        statusSliver = buildErrorSliver(
          context: context,
          error: asyncValue.error!,
          onRetry: onInvalidate,
          key: const ValueKey('error'),
        );
      } else if (!providerHasItems) {
        statusSliver = buildEmptyState(
          context: context,
          entityType: entityType,
          key: const ValueKey('empty'),
        );
      } else {
        statusSliver = const SliverFillRemaining(
          key: ValueKey('loading'),
          child: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      statusSliver = const SliverToBoxAdapter(
        key: ValueKey('none'),
        child: SizedBox.shrink(),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        buildAnimatedListOrGrid(
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

  /// Построение анимированного списка или сетки
  static Widget buildAnimatedListOrGrid({
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

    Widget listSliver;
    if (viewMode == ViewMode.list) {
      listSliver = SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        sliver: SliverAnimatedList(
          key: listKey,
          initialItemCount: displayedItems.length,
          itemBuilder: (context, index, animation) {
            if (index >= displayedItems.length) return const SizedBox.shrink();
            return buildItemTransition(
              context: context,
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
    } else {
      listSliver = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        sliver: SliverAnimatedGrid(
          key: gridKey,
          initialItemCount: displayedItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index, animation) {
            if (index >= displayedItems.length) return const SizedBox.shrink();
            return buildItemTransition(
              context: context,
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

    return SliverMainAxisGroup(
      key: key,
      slivers: [
        listSliver,
        buildFooter(
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          hasDisplayedItems: displayedItems.isNotEmpty,
        ),
      ],
    );
  }

  /// Построение перехода для элемента
  static Widget buildItemTransition({
    required BuildContext context,
    required WidgetRef ref,
    required BaseCardDto item,
    required Animation<double> animation,
    required ViewMode viewMode,
    required EntityType entityType,
    required DashboardCardCallbacks callbacks,
  }) {
    return FadeScaleTransition(
      animation: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: viewMode == ViewMode.list
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: buildListCardFor(
                  context: context,
                  ref: ref,
                  type: entityType,
                  item: item,
                  callbacks: callbacks,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: buildGridCardFor(
                  context: context,
                  ref: ref,
                  type: entityType,
                  item: item,
                  callbacks: callbacks,
                ),
              ),
      ),
    );
  }

  /// Построение удаленного элемента (для анимации удаления)
  static Widget buildRemovedItem({
    required BuildContext context,

    required WidgetRef ref,
    required BaseCardDto item,
    required Animation<double> animation,
    required ViewMode viewMode,
    required DashboardCardCallbacks callbacks,
    required EntityType entityType,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: viewMode == ViewMode.list
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
              ),
      ),
    );
  }

  /// Построение футера списка
  static Widget buildFooter({
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

  /// Построение пустого состояния
  static Widget buildEmptyState({
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

  /// Построение слайвера с ошибкой
  static Widget buildErrorSliver({
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

  /// Построение карточки для списка
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
    }

    if (!isDismissible) return card;

    return buildDismissible(
      context: context,
      ref: ref,
      child: card,
      item: item,
      callbacks: callbacks,
    );
  }

  /// Обертка в Dismissible виджет
  static Widget buildDismissible({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
    required BaseCardDto item,
    required DashboardCardCallbacks callbacks,
  }) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit, color: Colors.white),
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
          // Вправо → редактирование
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

    switch (type) {
      case EntityType.password:
        if (item is! PasswordCardDto) return noCorrectType;
        return PasswordGridCard(
          password: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.note:
        if (item is! NoteCardDto) return noCorrectType;
        return NoteGridCard(
          note: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.bankCard:
        if (item is! BankCardCardDto) return noCorrectType;
        return BankCardGridCard(
          bankCard: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
      case EntityType.file:
        if (item is! FileCardDto) return noCorrectType;
        return FileGridCard(
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
        return TotpGridCard(
          otp: item,
          onToggleFavorite: () => callbacks.onToggleFavorite(item.id),
          onTogglePin: () => callbacks.onTogglePin(item.id),
          onToggleArchive: () => callbacks.onToggleArchive(item.id),
          onDelete: () => callbacks.onDelete(item.id, item.isDeleted),
          onRestore: () => callbacks.onRestore(item.id),
        );
    }
  }
}
