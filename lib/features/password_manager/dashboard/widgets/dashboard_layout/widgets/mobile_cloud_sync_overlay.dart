import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';

class MobileCloudSyncOverlay extends ConsumerStatefulWidget {
  const MobileCloudSyncOverlay({super.key});

  @override
  ConsumerState<MobileCloudSyncOverlay> createState() =>
      _MobileCloudSyncOverlayState();
}

class _MobileCloudSyncOverlayState
    extends ConsumerState<MobileCloudSyncOverlay> {
  static const _initialHintDuration = Duration(milliseconds: 1200);

  bool _showInitialCheckHint = false;
  bool _handledInitialSnapshot = false;
  String? _currentStoreKey;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<StoreSyncStatus>>(currentStoreSyncProvider, (
      previous,
      next,
    ) {
      _handleSyncTransition(previous, next);
    });

    final syncState = ref.watch(currentStoreSyncProvider);
    _handleInitialSnapshot(syncState);
    final message = _messageForState(syncState);
    final systemPadding = MediaQuery.of(context).viewPadding;
    final visible = message != null;

    return IgnorePointer(
      ignoring: true,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -0.3),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, systemPadding.top + 12, 12, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  elevation: 6,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSyncTransition(
    AsyncValue<StoreSyncStatus>? previous,
    AsyncValue<StoreSyncStatus> next,
  ) {
    final status = next.hasValue ? next.requireValue : null;
    final previousStatus = previous?.hasValue == true
        ? previous!.requireValue
        : null;
    final currentStoreChanged =
        _storeKeyOf(previousStatus) != null &&
        _storeKeyOf(previousStatus) != _storeKeyOf(status);
    final finishedCheckWithBoundStore =
        previous?.isLoading == true &&
        status?.binding != null &&
        !(status!.isSyncInProgress && status.syncProgress != null);
    final swappedToBoundStoreWithoutVisibleLoading =
        currentStoreChanged &&
        status?.binding != null &&
        !(status!.isSyncInProgress && status.syncProgress != null);
    if (finishedCheckWithBoundStore || swappedToBoundStoreWithoutVisibleLoading) {
      _showHintTemporarily();
      return;
    }
    _handleSyncState(next);
  }

  void _handleInitialSnapshot(AsyncValue<StoreSyncStatus> syncState) {
    if (_handledInitialSnapshot) {
      return;
    }
    _handledInitialSnapshot = true;
    if (syncState.hasValue) {
      final status = syncState.requireValue;
      if (status.binding != null &&
          !(status.isSyncInProgress && status.syncProgress != null)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleSyncState(syncState, allowEphemeralCheckHint: true);
          }
        });
        return;
      }
    }
    _handleSyncState(syncState, allowEphemeralCheckHint: true);
  }

  void _handleSyncState(
    AsyncValue<StoreSyncStatus> syncState, {
    bool allowEphemeralCheckHint = false,
  }) {
    final status = syncState.hasValue ? syncState.requireValue : null;
    final nextStoreKey = status?.storeUuid ?? status?.storePath;
    final storeChanged =
        nextStoreKey != null && nextStoreKey != _currentStoreKey;
    if (nextStoreKey != _currentStoreKey) {
      _currentStoreKey = nextStoreKey;
      _hideTimer?.cancel();
      _showInitialCheckHint = false;
    }

    if (syncState.isLoading) {
      _hideTimer?.cancel();
      _setHintVisible(true);
      return;
    }

    if (status?.isSyncInProgress == true && status?.syncProgress != null) {
      _hideTimer?.cancel();
      _setHintVisible(false);
      return;
    }

    if (status?.binding != null &&
        (allowEphemeralCheckHint || storeChanged)) {
      _showHintTemporarily();
      return;
    }

    _hideTimer?.cancel();
    _setHintVisible(false);
  }

  void _showHintTemporarily() {
    _hideTimer?.cancel();
    _setHintVisible(true);
    _hideTimer = Timer(_initialHintDuration, () {
      if (mounted) {
        _setHintVisible(false);
      }
    });
  }

  void _setHintVisible(bool value) {
    if (_showInitialCheckHint == value || !mounted) {
      _showInitialCheckHint = value;
      return;
    }
    setState(() {
      _showInitialCheckHint = value;
    });
  }

  String? _storeKeyOf(StoreSyncStatus? status) {
    return status?.storeUuid ?? status?.storePath;
  }

  String? _messageForState(AsyncValue<StoreSyncStatus> syncState) {
    if (syncState.hasValue) {
      final status = syncState.requireValue;
      if (status.isSyncInProgress && status.syncProgress != null) {
        return '${status.syncProgress!.title} · шаг ${status.syncProgress!.stepIndex} из ${status.syncProgress!.totalSteps}';
      }
      if (_showInitialCheckHint && status.binding != null) {
        return 'Проверяем облачную версию хранилища...';
      }
      return null;
    }

    if (syncState.isLoading || _showInitialCheckHint) {
      return 'Проверяем облачную версию хранилища...';
    }

    return null;
  }
}
