import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoplixi/features/local_send/models/transfer_request.dart';
import 'package:hoplixi/features/local_send/models/transfer_state.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';

/// Диалог подтверждения входящей передачи файлов.
class ReceiveDialog extends ConsumerWidget {
  const ReceiveDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(incomingRequestProvider);
    final transferState = ref.watch(transferProvider);

    if (request == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, request),
              const SizedBox(height: 20),
              _buildFileList(context, request),
              if (request.text != null && request.text!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildTextPreview(context, request.text!),
              ],
              const SizedBox(height: 24),
              _buildProgressOrActions(context, ref, transferState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TransferRequest request) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.file_download_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Входящая передача',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'от ${request.senderDevice.name}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(BuildContext context, TransferRequest request) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (request.files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: request.files.length,
        separatorBuilder: (_, __) => const Divider(height: 12),
        itemBuilder: (context, index) {
          final file = request.files[index];
          return Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatFileSize(file.size),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Текст',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: textTheme.bodyMedium,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOrActions(
    BuildContext context,
    WidgetRef ref,
    TransferState transferState,
  ) {
    return switch (transferState) {
      TransferTransferring(:final progress, :final currentFile) =>
        _buildProgress(context, progress, currentFile),
      TransferConnecting() => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Подключение...'),
            ],
          ),
        ),
      ),
      TransferCompleted() => _buildCompleted(context, ref),
      _ => _buildActions(context, ref),
    };
  }

  Widget _buildProgress(
    BuildContext context,
    double progress,
    String currentFile,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Получение: $currentFile (${(progress * 100).toStringAsFixed(0)}%)',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.primary,
            size: 48,
          ),
          const SizedBox(height: 8),
          const Text('Получено!'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(transferProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            ref.read(transferProvider.notifier).rejectIncomingTransfer();
            Navigator.of(context).pop();
          },
          child: const Text('Отклонить'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () {
            ref.read(transferProvider.notifier).acceptIncomingTransfer();
          },
          child: const Text('Принять'),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
