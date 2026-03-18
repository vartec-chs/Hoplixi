import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/widgets/device_list_section.dart';
import 'package:hoplixi/features/local_send/widgets/local_send_status_section.dart';
import 'package:hoplixi/features/local_send/widgets/receive_dialog.dart';
import 'package:hoplixi/routing/paths.dart';
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
    _listenForRouteTransition();

    final sessionState = ref.watch(transferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Send'),
        leading: IconButton(
          onPressed: () {
            if (sessionState is SessionDisconnected) {
              context.pop();
              return;
            }

            ref.read(transferProvider.notifier).disconnect();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (sessionState is SessionDisconnected)
            IconButton(
              onPressed: () => context.push(AppRoutesPaths.localSendHistory),
              icon: const Icon(Icons.history),
              tooltip: 'История',
            ),
          if (sessionState is! SessionDisconnected)
            IconButton(
              onPressed: () => ref.read(transferProvider.notifier).disconnect(),
              icon: const Icon(Icons.close),
              tooltip: 'Завершить соединение',
            ),
        ],
      ),
      body: SafeArea(
        child: switch (sessionState) {
          SessionDisconnected() => const DeviceListSection(),
          SessionWaitingApproval() ||
          SessionConnecting() ||
          SessionConnected() ||
          SessionTransferring() => const LocalSendStatusSection(
            icon: Icons.sync,
            title: 'Открываем сеанс',
            subtitle: 'Переходим на экран обмена данными...',
            showProgress: true,
          ),
          SessionError(:final message) => LocalSendStatusSection(
            icon: Icons.error_outline,
            iconColor: Theme.of(context).colorScheme.error,
            title: 'Ошибка',
            subtitle: message,
            action: SmoothButton(
              onPressed: () => ref.read(transferProvider.notifier).disconnect(),
              label: 'Назад',
            ),
          ),
        },
      ),
    );
  }

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

  void _listenForRouteTransition() {
    ref.listen<SessionState>(transferProvider, (previous, next) {
      final shouldOpenTransfer = switch (next) {
        SessionWaitingApproval() ||
        SessionConnecting() ||
        SessionConnected() => true,
        _ => false,
      };

      final wasAlreadyInTransferFlow = switch (previous) {
        SessionWaitingApproval() ||
        SessionConnecting() ||
        SessionConnected() ||
        SessionTransferring() => true,
        _ => false,
      };

      if (!shouldOpenTransfer || wasAlreadyInTransferFlow || !mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final currentLocation = GoRouterState.of(context).matchedLocation;
        if (currentLocation != AppRoutesPaths.localSendTransfer) {
          context.push(AppRoutesPaths.localSendTransfer);
        }
      });
    });
  }
}
