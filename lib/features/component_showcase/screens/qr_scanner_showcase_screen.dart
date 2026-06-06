import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/qr_scanner/screens/qr_scanner_with_image_screen.dart';
import 'package:hoplixi/features/qr_scanner/screens/qr_scanner_with_camera_screen.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Экран для демонстрации QR-сканеров
class QrScannerShowcaseScreen extends StatefulWidget {
  const QrScannerShowcaseScreen({super.key});

  @override
  State<QrScannerShowcaseScreen> createState() =>
      _QrScannerShowcaseScreenState();
}

class _QrScannerShowcaseScreenState extends State<QrScannerShowcaseScreen> {
  String? _lastScannedData;
  String? _scannerUsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        _buildSection(
          context,
          title: 'QR-сканеры',
          description:
              'Два варианта сканирования QR-кодов: через камеру в реальном времени '
              'или через загрузку изображения.',
          children: const [],
        ),
        const SizedBox(height: 24),

        // Last scanned result
        if (_lastScannedData != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Последний результат',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_scannerUsed != null)
                      Chip(
                        label: Text(
                          _scannerUsed!,
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _lastScannedData!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _lastScannedData = null;
                          _scannerUsed = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Очистить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Scanner options
        _buildSection(
          context,
          title: 'Сканер с камеры',
          description:
              'Использует mobile_scanner для сканирования QR-кодов в реальном времени. '
              'Поддерживает вспышку и переключение камеры.',
          children: [
            SmoothButton(
              label: 'Открыть сканер камеры',
              icon: const Icon(Icons.camera_alt),
              type: SmoothButtonType.filled,
              isFullWidth: true,
              onPressed: () => _openCameraScanner(context),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildSection(
          context,
          title: 'Сканер из изображения',
          description:
              'Позволяет выбрать изображение из галереи или сделать фото, '
              'обрезать его и декодировать QR-код с помощью zxing2.',
          children: [
            SmoothButton(
              label: 'Открыть сканер изображений',
              icon: const Icon(Icons.image),
              type: SmoothButtonType.tonal,
              isFullWidth: true,
              onPressed: () => _openImageScanner(context),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Info cards
        _buildSection(
          context,
          title: 'Информация',
          children: [
            const NotificationCard(
              type: NotificationType.info,
              text:
                  'Оба сканера возвращают данные через context.pop(result) при подтверждении пользователем.',
            ),
            const SizedBox(height: 12),
            const NotificationCard(
              type: NotificationType.warning,
              text:
                  'Сканер камеры требует разрешения на доступ к камере. '
                  'На десктопе может работать некорректно без веб-камеры.',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Code examples
        _buildSection(
          context,
          title: 'Примеры использования',
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Навигация к сканеру:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '''// Сканер с камеры
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const QrScannerWithImageScreen(),
  ),
).then((result) {
  if (result != null) {
    print('Scanned: \$result');
  }
});

// Сканер из изображения
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const QrScannerWithCameraScreen(),
  ),
).then((result) {
  if (result != null) {
    print('Scanned: \$result');
  }
});''',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (children.isNotEmpty) ...[const SizedBox(height: 16), ...children],
      ],
    );
  }

  Future<void> _openCameraScanner(BuildContext context) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerWithCameraScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _lastScannedData = result;
        _scannerUsed = 'Камера';
      });
      Toaster.success(title: 'QR-код получен', description: 'Данные: $result');
    }
  }

  Future<void> _openImageScanner(BuildContext context) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerWithImageScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _lastScannedData = result;
        _scannerUsed = 'Изображение';
      });
      Toaster.success(title: 'QR-код получен', description: 'Данные: $result');
    }
  }
}
