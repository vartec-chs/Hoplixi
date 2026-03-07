import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/providers/discovery_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Нижний лист настроек обнаружения устройств.
///
/// Позволяет изменить:
/// - Имя устройства в mDNS (обычная функция).
/// - Принудительный IP-адрес интерфейса (экспериментальная функция).
class DiscoverySettingsSheet extends ConsumerStatefulWidget {
  const DiscoverySettingsSheet({super.key});

  @override
  ConsumerState<DiscoverySettingsSheet> createState() =>
      _DiscoverySettingsSheetState();
}

class _DiscoverySettingsSheetState
    extends ConsumerState<DiscoverySettingsSheet> {
  late final TextEditingController _nameController;

  /// Флаг: пользователь подтвердил предупреждение об экспериментальной функции.
  bool _experimentalUnlocked = false;

  @override
  void initState() {
    super.initState();
    final currentName =
        ref.read(discoverySettingsProvider).value?.customDeviceName ??
        Platform.localHostname;
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final settingsAsync = ref.watch(discoverySettingsProvider);
    final interfacesAsync = ref.watch(networkInterfacesProvider);

    final currentForcedIp = settingsAsync.value?.forcedIp;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Заголовок ──────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.settings_ethernet,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Настройки устройства',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Имя устройства ─────────────────────────────────────────
            Text(
              'Имя устройства',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              decoration: primaryInputDecoration(
                context,
                hintText: Platform.localHostname,
                helperText: 'Отображается другим устройствам в сети',

                prefixIcon: const Icon(Icons.devices),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Сбросить к имени хоста',
                  onPressed: () {
                    _nameController.text = Platform.localHostname;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SmoothButton(
              label: 'Сохранить имя',
              isFullWidth: true,
              icon: const Icon(Icons.check),
              onPressed: settingsAsync.isLoading
                  ? null
                  : () => _saveName(context),
            ),

            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // ── Экспериментальная: выбор IP ────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.biotech_outlined,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Сетевой интерфейс',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                _ExperimentalBadge(),
              ],
            ),
            const SizedBox(height: 10),

            // Предупреждение
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ручной выбор IP-адреса для mDNS-рекламы. '
                      'Неверный выбор может нарушить обнаружение устройств. '
                      'Используйте только если авто-определение выбирает неверный интерфейс (например, VPN).',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (!_experimentalUnlocked) ...[
              SmoothButton(
                label: 'Открыть настройки сети',
                type: SmoothButtonType.tonal,
                isFullWidth: true,
                icon: const Icon(Icons.lock_open_outlined),
                onPressed: () => _confirmExperimental(context),
              ),
            ] else ...[
              interfacesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Не удалось получить список интерфейсов: $e',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                data: (ifaces) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Авто-определение
                    _IpRadioTile(
                      label: 'Авто-определение',
                      sublabel: 'Рекомендуется',
                      value: null,
                      groupValue: currentForcedIp,
                      onChanged: (_) => _setForcedIp(null),
                    ),
                    // Интерфейсы
                    ...ifaces.map(
                      (entry) => _IpRadioTile(
                        label: entry.ifaceName,
                        sublabel: entry.ip,
                        value: entry.ip,
                        groupValue: currentForcedIp,
                        onChanged: (_) => _setForcedIp(entry.ip),
                      ),
                    ),
                    if (currentForcedIp != null) ...[
                      const SizedBox(height: 8),
                      SmoothButton(
                        label: 'Сбросить к авто-определению',
                        type: SmoothButtonType.outlined,
                        isFullWidth: true,
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _setForcedIp(null),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveName(BuildContext context) async {
    final name = _nameController.text.trim();
    await ref
        .read(discoverySettingsProvider.notifier)
        .setDeviceName(name.isEmpty ? null : name);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Имя устройства обновлено')));
    }
  }

  Future<void> _confirmExperimental(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.biotech_outlined),
        title: const Text('Экспериментальная функция'),
        content: const Text(
          'Ручной выбор сетевого интерфейса — нестабильная функция.\n\n'
          'Неверная настройка может привести к тому, что устройство '
          'не будет обнаружено в сети. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _experimentalUnlocked = true);
      // Загружаем список интерфейсов заранее.
      ref.invalidate(networkInterfacesProvider);
    }
  }

  Future<void> _setForcedIp(String? ip) async {
    await ref.read(discoverySettingsProvider.notifier).setForcedIp(ip);
    if (mounted && context.mounted) {
      final msg = ip == null
          ? 'IP-адрес сброшен на авто-определение'
          : 'Принудительный IP установлен: $ip';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// Метка «Эксперимент» рядом с заголовком секции.
class _ExperimentalBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'БЕТА',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Элемент списка с радиокнопкой для выбора IP-адреса.
class _IpRadioTile extends StatelessWidget {
  const _IpRadioTile({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String sublabel;
  final String? value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _selected
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: RadioListTile<String?>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        dense: true,
        title: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: _selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          sublabel,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
