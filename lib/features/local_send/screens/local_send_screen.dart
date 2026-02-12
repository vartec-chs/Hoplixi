import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/transfer_state.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/widgets/device_card.dart';
import 'package:hoplixi/features/local_send/widgets/receive_dialog.dart';

/// Экран отправки файлов и текста по локальной сети.
class LocalSendScreen extends ConsumerStatefulWidget {
  const LocalSendScreen({super.key});

  @override
  ConsumerState<LocalSendScreen> createState() => _LocalSendScreenState();
}

class _LocalSendScreenState extends ConsumerState<LocalSendScreen>
    with SingleTickerProviderStateMixin {
  final List<File> _selectedFiles = [];
  final _textController = TextEditingController();
  DeviceInfo? _selectedDevice;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForIncomingRequests();

    final transferState = ref.watch(transferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalSend'),
        centerTitle: true,
        actions: [
          if (transferState is! TransferIdle)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Сбросить',
              onPressed: () {
                ref.read(transferProvider.notifier).reset();
                setState(() {
                  _selectedFiles.clear();
                  _selectedDevice = null;
                  _textController.clear();
                });
              },
            ),
        ],
      ),
      body: switch (transferState) {
        TransferIdle() || TransferPreparing() => _buildContent(),
        TransferWaitingApproval() => _buildWaitingApproval(),
        TransferConnecting() => _buildConnecting(),
        TransferTransferring() => _buildTransferring(transferState),
        TransferCompleted() => _buildCompleted(),
        TransferRejected() => _buildRejected(),
        TransferCancelled() => _buildCancelled(),
        TransferError(:final message) => _buildError(message),
      },
    );
  }

  /// Слушает входящие запросы и показывает диалог.
  void _listenForIncomingRequests() {
    ref.listen(incomingRequestProvider, (prev, next) {
      if (next != null && prev == null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ReceiveDialog(),
        );
      }
    });
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilesSection(),
          const SizedBox(height: 24),
          _buildTextSection(),
          const SizedBox(height: 32),
          _buildDevicesSection(),
          const SizedBox(height: 24),
          _buildSendButton(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Секция файлов
  // ══════════════════════════════════════════════

  Widget _buildFilesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Файлы',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedFiles.isEmpty)
          _buildEmptyPlaceholder(
            icon: Icons.folder_open,
            text: 'Нет выбранных файлов',
          )
        else
          _buildFilesList(),
      ],
    );
  }

  Widget _buildFilesList() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _selectedFiles.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final name = file.path.split(Platform.pathSeparator).last;
          final size = file.lengthSync();

          return ListTile(
            dense: true,
            leading: Icon(
              Icons.insert_drive_file_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
            subtitle: Text(
              _formatFileSize(size),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 18, color: colorScheme.error),
              onPressed: () {
                setState(() => _selectedFiles.removeAt(index));
              },
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Секция текста
  // ══════════════════════════════════════════════

  Widget _buildTextSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Текст',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Введите текст для отправки (необязательно)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  //  Секция устройств
  // ══════════════════════════════════════════════

  Widget _buildDevicesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final devicesAsync = ref.watch(discoveryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) =>
                  Opacity(opacity: _pulseAnimation.value, child: child),
              child: Icon(
                Icons.wifi_tethering,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Устройства',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            devicesAsync.when(
              data: (devices) => Text(
                '${devices.length} найдено',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(
                'Ошибка',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        devicesAsync.when(
          data: (devices) => devices.isEmpty
              ? _buildEmptyPlaceholder(
                  icon: Icons.search,
                  text: 'Поиск устройств в сети...',
                )
              : _buildDevicesGrid(devices),
          loading: () => _buildEmptyPlaceholder(
            icon: Icons.search,
            text: 'Поиск устройств...',
          ),
          error: (e, _) => _buildEmptyPlaceholder(
            icon: Icons.error_outline,
            text: 'Ошибка: $e',
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesGrid(List<DeviceInfo> devices) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          isSelected: _selectedDevice?.id == device.id,
          onTap: () {
            setState(() => _selectedDevice = device);
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  //  Кнопка «Отправить»
  // ══════════════════════════════════════════════

  Widget _buildSendButton() {
    final hasData =
        _selectedFiles.isNotEmpty || _textController.text.trim().isNotEmpty;
    final enabled = hasData && _selectedDevice != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? _send : null,
        icon: const Icon(Icons.send),
        label: const Text('Отправить'),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Состояния передачи
  // ══════════════════════════════════════════════

  Widget _buildWaitingApproval() {
    return _buildStatusScreen(
      icon: Icons.hourglass_top,
      title: 'Ожидание подтверждения',
      subtitle:
          '${_selectedDevice?.name ?? "Устройство"} должно принять запрос',
      showProgress: true,
    );
  }

  Widget _buildConnecting() {
    return _buildStatusScreen(
      icon: Icons.link,
      title: 'Подключение',
      subtitle: 'Установка защищённого соединения...',
      showProgress: true,
    );
  }

  Widget _buildTransferring(TransferTransferring transferState) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: transferState.progress,
                      strokeWidth: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(transferState.progress * 100).toStringAsFixed(0)}%',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Отправка',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transferState.currentFile,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Файл ${transferState.currentIndex + 1} '
              'из ${transferState.totalFiles}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildStatusScreen(
      icon: Icons.check_circle_outline,
      iconColor: colorScheme.primary,
      title: 'Отправлено!',
      subtitle: 'Файлы успешно переданы',
      action: FilledButton(onPressed: _resetState, child: const Text('Готово')),
    );
  }

  Widget _buildRejected() {
    return _buildStatusScreen(
      icon: Icons.block,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Отклонено',
      subtitle: 'Получатель отклонил запрос',
      action: FilledButton(onPressed: _resetState, child: const Text('Назад')),
    );
  }

  Widget _buildCancelled() {
    return _buildStatusScreen(
      icon: Icons.cancel_outlined,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Отменено',
      subtitle: 'Передача была отменена',
      action: FilledButton(onPressed: _resetState, child: const Text('Назад')),
    );
  }

  Widget _buildError(String message) {
    return _buildStatusScreen(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Ошибка',
      subtitle: message,
      action: FilledButton(
        onPressed: _resetState,
        child: const Text('Повторить'),
      ),
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    bool showProgress = false,
    Widget? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: iconColor ?? colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showProgress) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Действия
  // ══════════════════════════════════════════════

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null) return;

    setState(() {
      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          _selectedFiles.add(File(platformFile.path!));
        }
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();

    ref
        .read(transferProvider.notifier)
        .sendToDevice(
          target: _selectedDevice!,
          files: _selectedFiles,
          text: text.isNotEmpty ? text : null,
        );
  }

  void _resetState() {
    ref.read(transferProvider.notifier).reset();
    setState(() {
      _selectedFiles.clear();
      _selectedDevice = null;
      _textController.clear();
    });
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
