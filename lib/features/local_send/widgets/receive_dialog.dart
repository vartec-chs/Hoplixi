import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/utils/platform_icons.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Диалог подтверждения входящего запроса на соединение.
class ReceiveDialog extends ConsumerWidget {
  const ReceiveDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peerDevice = ref.watch(incomingRequestProvider);

    // Автоматически закрываем при очистке запроса.
    ref.listen(incomingRequestProvider, (prev, next) {
      if (prev != null && next == null && context.mounted) {
        Navigator.of(context).pop();
      }
    });

    if (peerDevice == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, colorScheme, textTheme, peerDevice),
              const SizedBox(height: 24),
              _buildActions(context, ref, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    DeviceInfo peer,
  ) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            getPlatformIcon(peer.platform),
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Запрос на соединение',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '${peer.name} хочет подключиться',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          peer.ip,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SmoothButton(
          onPressed: () {
            ref.read(transferProvider.notifier).rejectIncomingSession();
          },
          label: 'Отклонить',
          type: .text,
          variant: .error,
        ),
        const SizedBox(width: 12),
        SmoothButton(
          onPressed: () {
            ref.read(transferProvider.notifier).acceptIncomingSession();
          },
          label: 'Принять',
          type: .filled,
          variant: .success,
        ),
      ],
    );
  }
}
