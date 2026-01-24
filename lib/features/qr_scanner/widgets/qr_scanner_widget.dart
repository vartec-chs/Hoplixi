import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/qr_scanner/screens/qr_scanner_with_camera_screen.dart';
import 'package:hoplixi/features/qr_scanner/screens/qr_scanner_with_image_screen.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:universal_platform/universal_platform.dart';

/// Режим сканирования QR-кода
enum QrScannerMode {
  /// Сканирование через камеру в реальном времени
  camera,

  /// Сканирование через выбор изображения
  image,
}

/// Виджет для сканирования QR-кодов с выбором режима.
///
/// Предоставляет пользователю выбор между сканированием через камеру
/// или загрузкой изображения. Результат возвращается через [onResult].
///
/// Пример использования:
/// ```dart
/// QrScannerWidget(
///   onResult: (data) {
///     print('Scanned QR: $data');
///   },
///   onCancel: () {
///     print('Scanning cancelled');
///   },
/// )
/// ```
class QrScannerWidget extends StatelessWidget {
  /// Callback, вызываемый при успешном сканировании QR-кода.
  final ValueChanged<String> onResult;

  /// Callback, вызываемый при отмене сканирования.
  /// Если не указан, кнопка отмены не отображается.
  final VoidCallback? onCancel;

  /// Заголовок виджета.
  final String? title;

  /// Подзаголовок виджета.
  final String? subtitle;

  /// Показывать ли режим камеры.
  /// По умолчанию true на мобильных устройствах, false на десктопе.
  final bool? showCameraMode;

  /// Показывать ли режим изображения.
  /// По умолчанию true.
  final bool showImageMode;

  /// Компактный режим отображения (только кнопки без заголовков).
  final bool compact;

  const QrScannerWidget({
    super.key,
    required this.onResult,
    this.onCancel,
    this.title,
    this.subtitle,
    this.showCameraMode,
    this.showImageMode = true,
    this.compact = false,
  });

  bool get _showCameraMode => showCameraMode ?? !UniversalPlatform.isDesktop;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (title != null || subtitle != null) ...[
            if (title != null)
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],

          // Scanner mode buttons
          _buildScannerButtons(context),

          // Cancel button
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            SmoothButton(
              label: 'Отмена',
              type: SmoothButtonType.text,
              isFullWidth: true,
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return _buildScannerButtons(context);
  }

  Widget _buildScannerButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Если доступен только один режим, показываем одну кнопку
    if (!_showCameraMode && showImageMode) {
      return SmoothButton(
        label: 'Сканировать QR-код',
        icon: const Icon(Icons.qr_code_scanner),
        type: SmoothButtonType.filled,
        isFullWidth: true,
        onPressed: () => _openImageScanner(context),
      );
    }

    if (_showCameraMode && !showImageMode) {
      return SmoothButton(
        label: 'Сканировать QR-код',
        icon: const Icon(Icons.qr_code_scanner),
        type: SmoothButtonType.filled,
        isFullWidth: true,
        onPressed: () => _openCameraScanner(context),
      );
    }

    // Оба режима доступны - показываем выбор
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera scanner option
        if (_showCameraMode)
          _ScannerOptionCard(
            icon: Icons.camera_alt,
            title: 'Камера',
            description: 'Сканировать QR-код в реальном времени',
            iconColor: colorScheme.primary,
            onTap: () => _openCameraScanner(context),
          ),

        if (_showCameraMode && showImageMode) const SizedBox(height: 12),

        // Image scanner option
        if (showImageMode)
          _ScannerOptionCard(
            icon: Icons.image,
            title: 'Изображение',
            description: 'Выбрать фото с QR-кодом из галереи',
            iconColor: colorScheme.secondary,
            onTap: () => _openImageScanner(context),
          ),
      ],
    );
  }

  Future<void> _openCameraScanner(BuildContext context) async {
    final globalNavigator = Navigator.of(context, rootNavigator: true);
    final result = await globalNavigator.push<String?>(
      MaterialPageRoute(builder: (_) => const QrScannerWithCameraScreen()),
    );

    if (result != null) {
      onResult(result);
    }
  }

  Future<void> _openImageScanner(BuildContext context) async {
    final globalNavigator = Navigator.of(context, rootNavigator: true);
    final result = await globalNavigator.push<String?>(
      MaterialPageRoute(
        builder: UniversalPlatform.isDesktop
            ? (_) => Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final titlebarState = ref.watch(titlebarStateProvider);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height:
                            titlebarState.hidden ||
                                titlebarState.backgroundTransparent
                            ? 0
                            : 40,
                      );
                    },
                  ),
                  Expanded(child: QrScannerWithImageScreen()),
                ],
              )
            : (_) => const QrScannerWithImageScreen(),
      ),
    );

    if (result != null) {
      onResult(result);
    }
  }
}

/// Карточка выбора режима сканирования
class _ScannerOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final VoidCallback onTap;

  const _ScannerOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показывает модальное окно с выбором режима сканирования QR-кода.
///
/// Возвращает [String] с данными QR-кода при успешном сканировании,
/// или `null` при отмене.
///
/// Пример использования:
/// ```dart
/// final result = await showQrScannerDialog(
///   context: context,
///   title: 'Сканировать QR-код',
/// );
/// if (result != null) {
///   print('Scanned: $result');
/// }
/// ```
Future<String?> showQrScannerDialog({
  required BuildContext context,
  String? title,
  String? subtitle,
  bool? showCameraMode,
  bool showImageMode = true,
}) async {
  String? scannedResult;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: QrScannerWidget(
            title: title ?? 'Сканировать QR-код',
            subtitle: subtitle ?? 'Выберите способ сканирования',
            showCameraMode: showCameraMode,
            showImageMode: showImageMode,
            onResult: (data) {
              scannedResult = data;
              Navigator.of(dialogContext).pop();
            },
            onCancel: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    },
  );

  return scannedResult;
}

/// Показывает bottom sheet с выбором режима сканирования QR-кода.
///
/// Возвращает [String] с данными QR-кода при успешном сканировании,
/// или `null` при отмене.
///
/// Пример использования:
/// ```dart
/// final result = await showQrScannerBottomSheet(
///   context: context,
/// );
/// if (result != null) {
///   print('Scanned: $result');
/// }
/// ```
Future<String?> showQrScannerBottomSheet({
  required BuildContext context,
  String? title,
  String? subtitle,
  bool? showCameraMode,
  bool showImageMode = true,
}) async {
  String? scannedResult;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: QrScannerWidget(
            title: title ?? 'Сканировать QR-код',
            subtitle: subtitle ?? 'Выберите способ сканирования',
            showCameraMode: showCameraMode,
            showImageMode: showImageMode,
            onResult: (data) {
              scannedResult = data;
              Navigator.of(sheetContext).pop();
            },
            onCancel: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
    },
  );

  return scannedResult;
}
