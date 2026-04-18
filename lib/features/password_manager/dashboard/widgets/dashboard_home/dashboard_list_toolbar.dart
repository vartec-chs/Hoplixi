import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

class DashboardListToolBar extends ConsumerStatefulWidget {
  const DashboardListToolBar({
    super.key,
    required this.entityType,
    required this.viewMode,
    required this.listState,
    this.isBulkMode = false,
    this.selectedCount = 0,
    this.onExitBulkMode,
    this.onBulkDelete,
    this.onBulkFavorite,
    this.bulkFavoriteLabel = 'В избранное',
    this.onBulkPin,
    this.bulkPinLabel = 'Закрепить',
    this.onBulkArchive,
    this.bulkArchiveLabel = 'В архив',
    this.onBulkAssignCategory,
    this.onBulkAssignTags,
  });

  final EntityType entityType;
  final ViewMode viewMode;
  final AsyncValue<DashboardListState<dynamic>> listState;
  final bool isBulkMode;
  final int selectedCount;
  final VoidCallback? onExitBulkMode;
  final VoidCallback? onBulkDelete;
  final VoidCallback? onBulkFavorite;
  final String bulkFavoriteLabel;
  final VoidCallback? onBulkPin;
  final String bulkPinLabel;
  final VoidCallback? onBulkArchive;
  final String bulkArchiveLabel;
  final VoidCallback? onBulkAssignCategory;
  final VoidCallback? onBulkAssignTags;

  @override
  ConsumerState<DashboardListToolBar> createState() =>
      _DashboardListToolBarState();
}

class _DashboardListToolBarState extends ConsumerState<DashboardListToolBar> {
  int? _cachedTotalCount;
  Timer? _updateTimer;
  bool _showLoadingIndicator = false;

  @override
  void initState() {
    super.initState();
    _initializeCachedCount();
  }

  @override
  void didUpdateWidget(DashboardListToolBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleListStateUpdate();
  }

  @override
  void dispose() {
    _cancelUpdateTimer();
    super.dispose();
  }

  void _initializeCachedCount() {
    final count = widget.listState.whenOrNull(
      data: (state) => state.totalCount,
    );
    if (count != null) {
      _cachedTotalCount = count;
    }
  }

  void _handleListStateUpdate() {
    final newCount = widget.listState.whenOrNull(
      data: (state) => state.totalCount,
    );

    if (widget.listState.hasError) {
      _cancelUpdateTimer();
      _setLoadingIndicator(false);
      return;
    }

    if (_isAwaitingData()) {
      _startUpdateDelay();
    } else {
      _cancelUpdateTimer();
      _setLoadingIndicator(false);

      // Обновляем кеш только если значение изменилось
      if (newCount != null && newCount != _cachedTotalCount) {
        setState(() {
          _cachedTotalCount = newCount;
        });
      }
    }
  }

  bool _isAwaitingData() {
    if (widget.listState.isLoading) {
      return true;
    }
    final data = widget.listState.whenOrNull(data: (state) => state);
    return data?.isLoading ?? false;
  }

  void _startUpdateDelay() {
    if (_showLoadingIndicator || _updateTimer != null) {
      return;
    }
    _updateTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      if (_isAwaitingData()) {
        _setLoadingIndicator(true);
      }
      _updateTimer = null;
    });
  }

  void _cancelUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void _setLoadingIndicator(bool value) {
    if (_showLoadingIndicator == value || !mounted) {
      return;
    }
    setState(() {
      _showLoadingIndicator = value;
    });
  }

  Future<bool> _confirmGridViewForSmallScreen() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Переключиться на карточки?'),
          content: const Text(
            'На маленьких экранах карточки могут быть менее удобны и не выполнять полный функционал. Продолжить?',
          ),
          actions: [
            SmoothButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              label: 'Отмена',
              type: SmoothButtonType.text,
            ),
            SmoothButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: 'Продолжить',
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBulkMode) {
      final isSmallScreen =
          MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;

      if (isSmallScreen) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Выбрано: ${widget.selectedCount}',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SmoothButton(
                onPressed: widget.onExitBulkMode,
                label: 'Отмена',
                type: SmoothButtonType.text,
                size: .preMedium,
              ),
              PopupMenuButton<_BulkMenuAction>(
                tooltip: 'Массовые действия',
                borderRadius: BorderRadius.circular(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _BulkMenuAction.favorite:
                      widget.onBulkFavorite?.call();
                    case _BulkMenuAction.pin:
                      widget.onBulkPin?.call();
                    case _BulkMenuAction.archive:
                      widget.onBulkArchive?.call();
                    case _BulkMenuAction.category:
                      widget.onBulkAssignCategory?.call();
                    case _BulkMenuAction.tags:
                      widget.onBulkAssignTags?.call();
                    case _BulkMenuAction.delete:
                      widget.onBulkDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.favorite,
                    enabled: widget.onBulkFavorite != null,
                    child: Row(
                      children: [
                        const Icon(Icons.star_border, size: 18),
                        const SizedBox(width: 8),
                        Text(widget.bulkFavoriteLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.pin,
                    enabled: widget.onBulkPin != null,
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(widget.bulkPinLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.archive,
                    enabled: widget.onBulkArchive != null,
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(widget.bulkArchiveLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.category,
                    enabled: widget.onBulkAssignCategory != null,
                    child: const Row(
                      children: [
                        Icon(Icons.category_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Категория'),
                      ],
                    ),
                  ),
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.tags,
                    enabled: widget.onBulkAssignTags != null,
                    child: const Row(
                      children: [
                        Icon(Icons.sell_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Теги'),
                      ],
                    ),
                  ),
                  PopupMenuItem<_BulkMenuAction>(
                    value: _BulkMenuAction.delete,
                    enabled: widget.onBulkDelete != null,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Удалить'),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Выбрано: ${widget.selectedCount}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SmoothButton(
                  onPressed: widget.onBulkFavorite,
                  icon: const Icon(Icons.star_border),
                  label: widget.bulkFavoriteLabel,
                  type: .outlined,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onBulkPin,
                  icon: const Icon(Icons.push_pin_outlined),
                  label: widget.bulkPinLabel,
                  type: .outlined,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onBulkArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: widget.bulkArchiveLabel,
                  type: .outlined,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onBulkAssignCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: 'Категория',
                  type: .outlined,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onBulkAssignTags,
                  icon: const Icon(Icons.sell_outlined),
                  label: 'Теги',
                  type: .outlined,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onBulkDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: 'Удалить',
                  type: .outlined,
                  variant: .error,
                  size: .preMedium,
                ),
                SmoothButton(
                  onPressed: widget.onExitBulkMode,
                  label: 'Отмена',
                  type: SmoothButtonType.text,
                  size: .preMedium,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Используем кешированное значение если оно есть и не показываем индикатор
    final isSmallScreen =
        MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;
    final displayCount = _showLoadingIndicator
        ? null
        : (_cachedTotalCount ??
              widget.listState.whenOrNull(data: (state) => state.totalCount));

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Кол-во:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                duration: const Duration(milliseconds: 300),
                child: _showLoadingIndicator
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : displayCount != null
                    ? Text(
                        key: ValueKey('count_$displayCount'),
                        '$displayCount',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
          ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            borderColor: Theme.of(context).dividerColor,
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            isSelected: [
              widget.viewMode == ViewMode.list,
              widget.viewMode == ViewMode.grid,
            ],
            onPressed: (i) async {
              if (i == 1 && isSmallScreen) {
                final confirmed = await _confirmGridViewForSmallScreen();
                if (!confirmed || !mounted) {
                  return;
                }
              }

              if (!mounted) {
                return;
              }

              ref
                  .read(currentViewModeProvider.notifier)
                  .setViewMode(i == 0 ? ViewMode.list : ViewMode.grid);
            },
            children: const [Icon(Icons.view_list), Icon(Icons.grid_view)],
          ),
        ],
      ),
    );
  }
}

enum _BulkMenuAction { favorite, pin, archive, category, tags, delete }
