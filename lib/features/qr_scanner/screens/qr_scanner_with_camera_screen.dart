/// QR Scanner Screen that uses live camera input for scanning QR codes.
///
/// This screen provides real-time QR code scanning using the device camera
/// via mobile_scanner package. When a QR code is detected, a confirmation
/// modal is shown using WoltModalSheet.
library;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// QR Scanner Screen that uses live camera for scanning QR codes.
class QrScannerWithCameraScreen extends StatefulWidget {
  const QrScannerWithCameraScreen({super.key});

  @override
  State<QrScannerWithCameraScreen> createState() =>
      _QrScannerWithCameraScreenState();
}

class _QrScannerWithCameraScreenState extends State<QrScannerWithCameraScreen>
    with WidgetsBindingObserver {
  static const String _logTag = 'QrScannerWithCameraScreen';

  late final MobileScannerController _controller;
  StreamSubscription<Object?>? _subscription;

  bool _isProcessing = false;
  bool _hasPermission = true;
  String? _errorMessage;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller with autoStart: false for manual lifecycle management
    _controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      returnImage: false,
    );

    // Start listening to lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Start listening to barcode events
    _subscription = _controller.barcodes.listen(_handleBarcode);

    // Start the scanner
    _startScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed
        _subscription = _controller.barcodes.listen(_handleBarcode);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes
    WidgetsBinding.instance.removeObserver(this);

    // Stop listening to barcode events
    unawaited(_subscription?.cancel());
    _subscription = null;

    // Dispose the widget itself
    super.dispose();

    // Finally, dispose of the controller
    await _controller.dispose();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
      if (mounted) {
        setState(() {
          _hasPermission = _controller.value.hasCameraPermission;
          _errorMessage = null;
        });
      }
    } on MobileScannerException catch (e) {
      logError('MobileScannerException: ${e.errorCode}', tag: _logTag);
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _errorMessage = _getErrorMessage(e.errorCode);
        });
      }
    } catch (e, stackTrace) {
      logError(
        'Error starting scanner: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка запуска камеры: $e';
        });
      }
    }
  }

  String _getErrorMessage(MobileScannerErrorCode errorCode) {
    switch (errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Доступ к камере запрещён. Пожалуйста, разрешите доступ в настройках.';
      case MobileScannerErrorCode.unsupported:
        return 'Камера не поддерживается на этом устройстве.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'Контроллер камеры уже инициализирован.';
      case MobileScannerErrorCode.controllerDisposed:
        return 'Контроллер камеры был закрыт.';
      case MobileScannerErrorCode.controllerUninitialized:
        return 'Контроллер камеры не инициализирован.';
      case MobileScannerErrorCode.genericError:
      default:
        return 'Произошла ошибка при работе с камерой.';
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    // Prevent multiple processing at once
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    logInfo('QR code detected: $rawValue', tag: _logTag);

    // Set processing flag to prevent duplicate scans
    setState(() => _isProcessing = true);

    // Stop the scanner temporarily
    unawaited(_controller.stop());

    // Show the result modal
    _showResultModal(rawValue);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() {
        _torchEnabled = _controller.value.torchState == TorchState.on;
      });
    } catch (e) {
      logError('Error toggling torch: $e', tag: _logTag);
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      logError('Error switching camera: $e', tag: _logTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер QR-кода'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Torch toggle button
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.yellow : null,
            ),
            onPressed: _toggleTorch,
            tooltip: _torchEnabled ? 'Выключить вспышку' : 'Включить вспышку',
          ),
          // Switch camera button
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
            tooltip: 'Переключить камеру',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_hasPermission && _errorMessage == null)
            MobileScanner(
              controller: _controller,
              onDetect: (_) {}, // We use stream subscription instead
              errorBuilder: (context, error) {
                return _buildErrorView(
                  context,
                  _getErrorMessage(error.errorCode),
                );
              },
            )
          else
            _buildErrorView(context, _errorMessage ?? 'Нет доступа к камере'),

          // Scan overlay
          if (_hasPermission && _errorMessage == null)
            _buildScanOverlay(context),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(context),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Обработка...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: colorScheme.error.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Ошибка камеры',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SmoothButton(
                label: 'Повторить',
                type: SmoothButtonType.filled,
                onPressed: _startScanner,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return CustomPaint(
      size: size,
      painter: _ScanOverlayPainter(
        scanAreaSize: scanAreaSize,
        borderColor: colorScheme.primary,
        overlayColor: Colors.black54,
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Наведите камеру на QR-код',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Код будет распознан автоматически',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultModal(String qrData) async {
    final result = await WoltModalSheet.show<String?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      pageListBuilder: (modalContext) {
        return [_buildResultPage(modalContext, qrData)];
      },
    );

    if (result != null && mounted) {
      // User confirmed, return the data
      context.pop(result);
    } else if (mounted) {
      // User cancelled, resume scanning
      setState(() => _isProcessing = false);
      unawaited(_controller.start());
    }
  }

  WoltModalSheetPage _buildResultPage(
    BuildContext modalContext,
    String qrData,
  ) {
    final theme = Theme.of(modalContext);
    final colorScheme = theme.colorScheme;

    return WoltModalSheetPage(
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      topBarTitle: Text('QR-код распознан', style: theme.textTheme.titleMedium),
      isTopBarLayerAlwaysVisible: true,
      leadingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(modalContext).pop(null),
      ),
      stickyActionBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmoothButton(
              label: 'Использовать данные',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.success,
              isFullWidth: true,
              onPressed: () => Navigator.of(modalContext).pop(qrData),
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Сканировать другой',
              type: SmoothButtonType.outlined,
              isFullWidth: true,
              onPressed: () => Navigator.of(modalContext).pop(null),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_2,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Label
            Text(
              'Содержимое QR-кода:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // QR Data container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    qrData,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${qrData.length} символов',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrData));
                          Toaster.success(
                            title: 'Скопировано',
                            description: 'Данные скопированы в буфер обмена',
                          );
                        },
                        tooltip: 'Копировать',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info message
            const NotificationCard(
              type: NotificationType.info,
              text:
                  'Нажмите "Использовать данные", чтобы передать содержимое QR-кода, '
                  'или "Сканировать другой" чтобы продолжить сканирование.',
            ),

            // Bottom padding for sticky action bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the scan overlay with cutout
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;
  final Color overlayColor;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Draw border around scan area
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );

    // Draw corner accents
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerLength),
      Offset(scanRect.left, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaSize != scanAreaSize ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.overlayColor != overlayColor;
  }
}
