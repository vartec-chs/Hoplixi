import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/widgets/device_card.dart';
import 'package:hoplixi/features/local_send/widgets/receive_dialog.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:open_filex/open_filex.dart' as open_filex;

/// Экран обмена файлами и текстом по локальной сети.
class LocalSendScreen extends ConsumerStatefulWidget {
  const LocalSendScreen({super.key});

  @override
  ConsumerState<LocalSendScreen> createState() => _LocalSendScreenState();
}

class _LocalSendScreenState extends ConsumerState<LocalSendScreen>
    with SingleTickerProviderStateMixin {
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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForIncomingRequests();

    final sessionState = ref.watch(transferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalSend'),
        centerTitle: true,
        actions: [
          if (sessionState is! SessionDisconnected)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Отключиться',
              onPressed: () {
                ref.read(transferProvider.notifier).disconnect();
              },
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
            SessionDisconnected() => KeyedSubtree(
              key: const ValueKey('disconnected'),
              child: _buildDeviceList(),
            ),
            SessionWaitingApproval(:final peer) => KeyedSubtree(
              key: const ValueKey('waiting'),
              child: _buildStatusScreen(
                icon: Icons.hourglass_top,
                title: 'Ожидание подтверждения',
                subtitle: '${peer.name} должен принять запрос',
                showProgress: true,
              ),
            ),
            SessionConnecting(:final peer) => KeyedSubtree(
              key: const ValueKey('connecting'),
              child: _buildStatusScreen(
                icon: Icons.link,
                title: 'Подключение',
                subtitle: 'Установка соединения с ${peer.name}...',
                showProgress: true,
              ),
            ),
            SessionConnected(:final peer) => KeyedSubtree(
              key: const ValueKey('connected'),
              child: _buildSessionScreen(peer),
            ),
            SessionTransferring() => KeyedSubtree(
              key: const ValueKey('transferring'),
              child: _buildTransferringScreen(sessionState),
            ),
            SessionError(:final message) => KeyedSubtree(
              key: const ValueKey('error'),
              child: _buildStatusScreen(
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

  // ══════════════════════════════════════════════
  //  Список устройств (disconnected)
  // ══════════════════════════════════════════════

  Widget _buildDeviceList() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final devicesAsync = ref.watch(discoveryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
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
                error: (_, _) => Text(
                  'Ошибка',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Нажмите на устройство, чтобы подключиться',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildDevicesGrid(List<DeviceInfo> devices) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    if (isSmallScreen) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = devices[index];
          return DeviceCard(
            device: device,
            onTap: () {
              ref.read(transferProvider.notifier).connectToDevice(device);
            },
          );
        },
      );
    }

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
          onTap: () {
            ref.read(transferProvider.notifier).connectToDevice(device);
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  //  Экран активной сессии (connected)
  // ══════════════════════════════════════════════

  Widget _buildSessionScreen(DeviceInfo peer) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Верхняя часть: пир + действия.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectedPeerCard(peer, colorScheme, textTheme),
              const SizedBox(height: 20),
              Text(
                'Отправить',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactAction(
                      icon: Icons.attach_file,
                      label: 'Файлы',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onTap: _pickAndSendFiles,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactAction(
                      icon: Icons.text_fields,
                      label: 'Текст',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onTap: _showSendTextDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // История обмена — скроллируемая.
        Expanded(child: _buildHistoryList(colorScheme, textTheme)),

        // Кнопка отключения — закреплена внизу.
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SmoothButton(
              onPressed: () {
                ref.read(transferProvider.notifier).disconnect();
              },
              icon: const Icon(Icons.link_off),
              label: 'Отключиться',
              variant: .error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedPeerCard(
    DeviceInfo peer,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _platformIcon(peer.platform),
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, color: colorScheme.primary, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      'Подключено • ${peer.ip}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme, TextTheme textTheme) {
    final history = ref.watch(sessionHistoryProvider);

    if (history.isEmpty) {
      return Center(
        child: Text(
          'История обмена пуста',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'История обмена',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              // reversed list
              itemBuilder: (context, index) {
                final item = history[history.length - 1 - index];
                return _buildHistoryTile(item, colorScheme, textTheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
    HistoryItem item,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final icon = item.isFile
        ? (item.isSent ? Icons.upload_file : Icons.download)
        : (item.isSent ? Icons.send : Icons.message);

    final directionLabel = item.isSent ? 'Отправлено' : 'Получено';

    final iconColor = item.isSent ? colorScheme.primary : colorScheme.tertiary;

    final time =
        '${item.timestamp.hour.toString().padLeft(2, '0')}'
        ':${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.isFile && item.filePath != null) {
            open_filex.OpenFilex.open(item.filePath!);
          } else if (!item.isFile) {
            Clipboard.setData(ClipboardData(text: item.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Текст скопирован в буфер обмена')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.content,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$directionLabel • $time',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isFile || item.filePath != null)
                Icon(
                  item.isFile ? Icons.folder_open : Icons.copy,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Экран передачи (transferring)
  // ══════════════════════════════════════════════

  Widget _buildTransferringScreen(SessionTransferring s) {
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
                      value: s.progress,
                      strokeWidth: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                  Text(
                    '${(s.progress * 100).toStringAsFixed(0)}'
                    '%',
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
              s.isSending ? 'Отправка' : 'Получение',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.currentFile,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (s.totalFiles > 1) ...[
              const SizedBox(height: 4),
              Text(
                'Файл ${s.currentIndex + 1} '
                'из ${s.totalFiles}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Общие виджеты
  // ══════════════════════════════════════════════

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

  Future<void> _pickAndSendFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final files = <File>[];
    for (final platformFile in result.files) {
      if (platformFile.path != null) {
        files.add(File(platformFile.path!));
      }
    }

    if (files.isNotEmpty) {
      await ref.read(transferProvider.notifier).sendFiles(files);
    }
  }

  Future<void> _showSendTextDialog() async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить текст'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Введите текст',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context),
            label: 'Отмена',
            type: .text,
          ),
          SmoothButton(
            onPressed: () => Navigator.pop(context, controller.text),
            label: 'Отправить',
            type: .filled,
          ),
        ],
      ),
    );

    if (text != null && text.trim().isNotEmpty) {
      await ref
          .read(transferProvider.notifier)
          .sendText(text.trim())
          .then((_) => controller.dispose());
    } else {
      controller.dispose();
    }
  }

  IconData _platformIcon(String platform) {
    return switch (platform) {
      'android' => Icons.phone_android,
      'ios' => Icons.phone_iphone,
      'windows' => Icons.desktop_windows,
      'macos' => Icons.laptop_mac,
      'linux' => Icons.computer,
      _ => Icons.devices,
    };
  }
}
