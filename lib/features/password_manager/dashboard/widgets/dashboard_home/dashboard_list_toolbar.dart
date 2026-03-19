import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';

class DashboardListToolBar extends ConsumerStatefulWidget {
  const DashboardListToolBar({
    super.key,
    required this.entityType,
    required this.viewMode,
    required this.listState,
  });

  final EntityType entityType;
  final ViewMode viewMode;
  final AsyncValue<DashboardListState<dynamic>> listState;

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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Продолжить'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
