import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/widgets/connected_session_section.dart';
import 'package:hoplixi/features/local_send/widgets/local_send_status_section.dart';
import 'package:hoplixi/features/local_send/widgets/transferring_section.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

class LocalSendTransferScreen extends ConsumerWidget {
  const LocalSendTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep session history alive while the transfer flow screen is mounted.
    ref.watch(sessionHistoryProvider);

    ref.listen<SessionState>(transferProvider, (previous, next) {
      if (next is! SessionDisconnected) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLocation = GoRouterState.of(context).matchedLocation;
        if (currentLocation != AppRoutesPaths.localSendSend) {
          // context.go(AppRoutesPaths.localSendSend);
          context.pop();
        }
      });
    });

    final sessionState = ref.watch(transferProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(transferProvider.notifier).disconnect();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local Send'),
          leading: IconButton(
            onPressed: () => ref.read(transferProvider.notifier).disconnect(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () => ref.read(transferProvider.notifier).disconnect(),
              icon: const Icon(Icons.close),
              tooltip: 'Завершить соединение',
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.92,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            child: switch (sessionState) {
              SessionWaitingApproval(:final peer) => KeyedSubtree(
                key: const ValueKey('waiting'),
                child: LocalSendStatusSection(
                  icon: Icons.hourglass_top,
                  title: 'Ожидание подтверждения',
                  subtitle: '${peer.name} должен принять запрос',
                  showProgress: true,
                ),
              ),
              SessionConnecting(:final peer) => KeyedSubtree(
                key: const ValueKey('connecting'),
                child: LocalSendStatusSection(
                  icon: Icons.link,
                  title: 'Подключение',
                  subtitle: 'Установка соединения с ${peer.name}...',
                  showProgress: true,
                ),
              ),
              SessionConnected(:final peer) => KeyedSubtree(
                key: const ValueKey('connected'),
                child: ConnectedSessionSection(peer: peer),
              ),
              SessionTransferring() => KeyedSubtree(
                key: const ValueKey('transferring'),
                child: TransferringSection(sessionState: sessionState),
              ),
              SessionError(:final message) => KeyedSubtree(
                key: const ValueKey('error'),
                child: LocalSendStatusSection(
                  icon: Icons.error_outline,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: 'Ошибка',
                  subtitle: message,
                  action: SmoothButton(
                    onPressed: () =>
                        ref.read(transferProvider.notifier).disconnect(),
                    label: 'Назад',
                  ),
                ),
              ),
              SessionDisconnected() => const KeyedSubtree(
                key: ValueKey('disconnected'),
                child: LocalSendStatusSection(
                  icon: Icons.wifi_tethering_off,
                  title: 'Сеанс завершён',
                  subtitle: 'Возвращаемся к поиску устройств...',
                  showProgress: true,
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}
