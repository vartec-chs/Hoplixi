import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/widgets/connected_session_section.dart';
import 'package:hoplixi/features/local_send/widgets/device_list_section.dart';
import 'package:hoplixi/features/local_send/widgets/local_send_status_section.dart';
import 'package:hoplixi/features/local_send/widgets/receive_dialog.dart';
import 'package:hoplixi/features/local_send/widgets/transferring_section.dart';
import 'package:hoplixi/shared/ui/button.dart';

class LocalSendScreen extends ConsumerStatefulWidget {
  const LocalSendScreen({super.key});

  @override
  ConsumerState<LocalSendScreen> createState() => _LocalSendScreenState();
}

class _LocalSendScreenState extends ConsumerState<LocalSendScreen> {
  @override
  Widget build(BuildContext context) {
    _listenForIncomingRequests();

    final sessionState = ref.watch(transferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Send'),
        actions: [
          if (sessionState is SessionConnected ||
              sessionState is SessionTransferring)
            IconButton(
              onPressed: () => ref.read(transferProvider.notifier).disconnect(),
              icon: const Icon(Icons.close),
              tooltip: 'Завершить соединение',
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: switch (sessionState) {
            SessionDisconnected() => const KeyedSubtree(
              key: ValueKey('disconnected'),
              child: DeviceListSection(),
            ),
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
          },
        ),
      ),
    );
  }

  /// Прослушивает состояние incomingRequestProvider для показа диалогов.
  void _listenForIncomingRequests() {
    ref.listen(incomingRequestProvider, (previous, next) {
      if (next != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ReceiveDialog(),
        );
      }
    });
  }
}
