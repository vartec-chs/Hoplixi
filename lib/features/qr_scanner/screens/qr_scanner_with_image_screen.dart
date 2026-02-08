/// QR Scanner Screen that uses image input for scanning QR codes.
///
/// This screen allows users to:
/// 1. Pick an image from gallery or camera
/// 2. Crop the image to focus on QR code (using crop_image on desktop,
///    image_cropper on mobile)
/// 3. Decode QR code using zxing2
/// 4. Show result in WoltModalSheet for confirmation
library;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:zxing2/qrcode.dart';

/// Custom aspect ratio preset for QR codes (square) - used on mobile
class _QrAspectRatioPreset implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (1, 1);

  @override
  String get name => 'Квадрат (QR)';
}

/// QR Scanner Screen that uses image input for scanning QR codes.
class QrScannerWithImageScreen extends StatefulWidget {
  const QrScannerWithImageScreen({super.key});

  @override
  State<QrScannerWithImageScreen> createState() =>
      _QrScannerWithImageScreenState();
}

class _QrScannerWithImageScreenState extends State<QrScannerWithImageScreen> {
  static const String _logTag = 'QrScannerWithImageScreen';
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isProcessFileSelect = false;
  String? _errorMessage;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Request focus to receive keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Handle keyboard shortcuts (Ctrl+V for paste)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

      // Ctrl+V (Windows/Linux) or Cmd+V (macOS)
      if ((isCtrlPressed || isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyV) {
        _handlePaste();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Handle paste from clipboard
  Future<void> _handlePaste() async {
    if (_isProcessFileSelect || _isLoading) return;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      // Check if clipboard has image data
      final hasImage = await _checkClipboardForImage();

      if (hasImage) {
        await _pasteImageFromClipboard();
      } else if (clipboardData?.text != null) {
        // If it's text, show a toast that we need an image
        Toaster.info(
          title: 'Вставка текста',
          description: 'Для сканирования вставьте изображение с QR-кодом',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Error handling paste: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if clipboard contains image
  Future<bool> _checkClipboardForImage() async {
    try {
      if (UniversalPlatform.isDesktop) {
        final imageBytes = await Pasteboard.image;
        return imageBytes != null && imageBytes.isNotEmpty;
      }
      return false;
    } catch (e) {
      logWarning('Could not check clipboard for image: $e', tag: _logTag);
      return false;
    }
  }

  /// Get image bytes from clipboard using pasteboard package
  Future<Uint8List?> _getImageFromClipboard() async {
    try {
      if (UniversalPlatform.isDesktop) {
        final imageBytes = await Pasteboard.image;
        if (imageBytes != null && imageBytes.isNotEmpty) {
          logInfo(
            'Got image from clipboard: ${imageBytes.length} bytes',
            tag: _logTag,
          );
          return imageBytes;
        }
      }
      return null;
    } catch (e) {
      logWarning('Could not get image from clipboard: $e', tag: _logTag);
      return null;
    }
  }

  /// Paste image from clipboard and process it
  Future<void> _pasteImageFromClipboard() async {
    setState(() {
      _isProcessFileSelect = true;
      _errorMessage = null;
    });

    try {
      final imageBytes = await _getImageFromClipboard();

      if (imageBytes == null || imageBytes.isEmpty) {
        Toaster.info(
          title: 'Нет изображения',
          description:
              'В буфере обмена нет изображения. Скопируйте изображение с QR-кодом.',
        );
        setState(() => _isProcessFileSelect = false);
        return;
      }

      // Save to temp file first
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/pasted_qr_$timestamp.png');
      await tempFile.writeAsBytes(imageBytes);

      // Open crop dialog
      if (mounted) {
        if (UniversalPlatform.isDesktop) {
          final croppedFile = await _cropImageDesktop(tempFile.path);
          if (croppedFile != null) {
            setState(() {
              _selectedImage = croppedFile;
              _isProcessFileSelect = false;
            });
            return;
          }
        } else {
          final mobileCropped = await _cropImageMobile(tempFile.path);
          if (mobileCropped != null) {
            setState(() {
              _selectedImage = File(mobileCropped.path);
              _isProcessFileSelect = false;
            });
            return;
          }
        }

        // User cancelled crop, don't select the image
        setState(() => _isProcessFileSelect = false);
      }
    } catch (e, stackTrace) {
      logError('Error pasting image: $e', tag: _logTag, stackTrace: stackTrace);
      setState(() {
        _isProcessFileSelect = false;
        _errorMessage = 'Ошибка вставки изображения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Сканер QR-кода'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Paste button
            if (UniversalPlatform.isDesktop)
              Tooltip(
                message: 'Вставить из буфера (Ctrl+V)',
                child: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _isProcessFileSelect || _isLoading
                      ? null
                      : _handlePaste,
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Выберите изображение с QR-кодом',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  UniversalPlatform.isDesktop
                      ? 'Выберите изображение из галереи, сделайте фото или вставьте из буфера (Ctrl+V). '
                            'После выбора вы сможете обрезать изображение для лучшего распознавания.'
                      : 'Выберите изображение из галереи или сделайте фото. '
                            'После выбора вы сможете обрезать изображение для лучшего распознавания.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Image preview area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.3),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: _buildImagePreview(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  NotificationCard(
                    type: NotificationType.error,
                    text: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isProcessFileSelect || _isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isProcessFileSelect
                  ? 'Выбор и обработка файла...'
                  : 'Сканирование QR-кода...',
            ),
          ],
        ),
      );
    }

    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_selectedImage!, fit: BoxFit.contain),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: _clearImage,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _pickImage(ImageSource.gallery),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Нажмите для выбора изображения',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pick from gallery / camera row
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: SmoothButton(
                label: 'Галерея',
                icon: const Icon(Icons.photo_library_outlined),
                type: SmoothButtonType.tonal,
                onPressed: _isProcessFileSelect || _isLoading
                    ? null
                    : () => _pickImage(ImageSource.gallery),
              ),
            ),

            if (UniversalPlatform.isMobile)
              Expanded(
                child: SmoothButton(
                  label: 'Камера',
                  icon: const Icon(Icons.camera_alt_outlined),
                  type: SmoothButtonType.tonal,
                  onPressed: _isProcessFileSelect || _isLoading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Scan button
        SmoothButton(
          label: 'Сканировать QR-код',
          icon: const Icon(Icons.qr_code),
          type: SmoothButtonType.filled,
          isFullWidth: true,
          loading: _isProcessFileSelect || _isLoading,
          onPressed:
              _selectedImage != null && !(_isProcessFileSelect || _isLoading)
              ? _scanQrCode
              : null,
        ),
      ],
    );
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessFileSelect = true;
        _errorMessage = null;
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        setState(() => _isProcessFileSelect = false);
        return;
      }

      // Use different cropper based on platform
      File? croppedFile;
      if (UniversalPlatform.isDesktop) {
        croppedFile = await _cropImageDesktop(pickedFile.path);
      } else {
        final mobileCropped = await _cropImageMobile(pickedFile.path);
        if (mobileCropped != null) {
          croppedFile = File(mobileCropped.path);
        }
      }

      if (croppedFile != null) {
        setState(() {
          _selectedImage = croppedFile;
          _isProcessFileSelect = false;
        });
      } else {
        // User cancelled crop, don't select the image
        setState(() => _isProcessFileSelect = false);
      }
    } on PlatformException catch (e) {
      logError('Platform exception during image pick: $e', tag: _logTag);
      setState(() {
        _isProcessFileSelect = false;
        _errorMessage =
            'Ошибка доступа к ${source == ImageSource.camera ? 'камере' : 'галерее'}: ${e.message}';
      });
    } catch (e, stackTrace) {
      logError('Error picking image: $e', tag: _logTag, stackTrace: stackTrace);
      setState(() {
        _isProcessFileSelect = false;
        _errorMessage = 'Ошибка выбора изображения: $e';
      });
    }
  }

  /// Crop image using crop_image package (for desktop platforms)
  Future<File?> _cropImageDesktop(String sourcePath) async {
    final imageBytes = await File(sourcePath).readAsBytes();

    if (!mounted) return null;

    final result = await showDialog<ui.Image?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DesktopCropDialog(imageBytes: imageBytes),
    );

    if (result == null) return null;

    try {
      // Convert ui.Image to bytes
      final byteData = await result.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/cropped_qr_$timestamp.png');
      await tempFile.writeAsBytes(bytes);

      logInfo('Image cropped and saved to: ${tempFile.path}', tag: _logTag);
      return tempFile;
    } catch (e, stackTrace) {
      logError(
        'Error saving cropped image: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Crop image using image_cropper package (for mobile platforms)
  Future<CroppedFile?> _cropImageMobile(String sourcePath) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Обрезать изображение',
            toolbarColor: colorScheme.primary,
            toolbarWidgetColor: colorScheme.onPrimary,
            activeControlsWidgetColor: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            dimmedLayerColor: Colors.black54,
            cropFrameColor: colorScheme.primary,
            cropGridColor: colorScheme.primary.withOpacity(0.5),
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              _QrAspectRatioPreset(),
            ],
          ),
          IOSUiSettings(
            title: 'Обрезать изображение',
            doneButtonTitle: 'Готово',
            cancelButtonTitle: 'Отмена',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              _QrAspectRatioPreset(),
            ],
          ),
          WebUiSettings(context: context),
        ],
      );

      return croppedFile;
    } catch (e, stackTrace) {
      logError(
        'Error cropping image: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      Toaster.error(title: 'Ошибка обрезки', description: e.toString());
      return null;
    }
  }

  Future<void> _scanQrCode() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _decodeQrCode(_selectedImage!);

      if (result != null) {
        if (mounted) {
          await _showResultModal(result);
        }
      } else {
        setState(() {
          _errorMessage =
              'QR-код не найден на изображении. '
              'Попробуйте выбрать другое изображение или обрезать его так, '
              'чтобы QR-код занимал большую часть кадра.';
        });
      }
    } catch (e, stackTrace) {
      logError(
        'Error scanning QR code: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = 'Ошибка сканирования: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _decodeQrCode(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final result = await compute(_decodeQrCodeInIsolate, bytes);

      if (result != null) {
        logInfo('QR code decoded successfully: $result', tag: _logTag);
      } else {
        logInfo('QR code not found in image', tag: _logTag);
      }

      return result;
    } catch (e, stackTrace) {
      logError(
        'Error decoding QR code: $e',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _showResultModal(String qrData) async {
    final result = await WoltModalSheet.show<String?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      pageListBuilder: (modalContext) {
        return [_buildResultPage(modalContext, qrData)];
      },
    );

    // If user confirmed, return the data
    if (result != null && mounted) {
      context.pop(result);
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
              label: 'Отмена',
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
                  'Нажмите "Использовать данные", чтобы передать содержимое QR-кода.',
            ),

            // Bottom padding for sticky action bar
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

/// Desktop crop dialog using crop_image package
class _DesktopCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const _DesktopCropDialog({required this.imageBytes});

  @override
  State<_DesktopCropDialog> createState() => _DesktopCropDialogState();
}

class _DesktopCropDialogState extends State<_DesktopCropDialog> {
  late final CropController _cropController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cropController = CropController(
      aspectRatio: 1.0, // Square for QR codes
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final windowHeight = UniversalPlatform.isDesktop
        ? MediaQuery.of(context).size.height
        : double.infinity;
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: windowHeight * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.crop, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Обрезать изображение',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            // Crop area
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CropImage(
                  controller: _cropController,
                  image: Image.memory(widget.imageBytes),
                  gridColor: colorScheme.primary,
                  gridCornerColor: colorScheme.primary,
                  gridInnerColor: colorScheme.primary.withOpacity(0.5),
                  scrimColor: Colors.black54,
                  alwaysShowThirdLines: true,
                  minimumImageSize: 50,
                ),
              ),
            ),

            // Aspect ratio options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AspectRatioButton(
                    label: 'Свободно',
                    isSelected: _cropController.aspectRatio == null,
                    onTap: () {
                      setState(() {
                        _cropController.aspectRatio = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioButton(
                    label: '1:1',
                    isSelected: _cropController.aspectRatio == 1.0,
                    onTap: () {
                      setState(() {
                        _cropController.aspectRatio = 1.0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioButton(
                    label: '4:3',
                    isSelected: _cropController.aspectRatio == 4.0 / 3.0,
                    onTap: () {
                      setState(() {
                        _cropController.aspectRatio = 4.0 / 3.0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioButton(
                    label: '16:9',
                    isSelected: _cropController.aspectRatio == 16.0 / 9.0,
                    onTap: () {
                      setState(() {
                        _cropController.aspectRatio = 16.0 / 9.0;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Rotation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.rotate_left),
                    tooltip: 'Повернуть влево',
                    onPressed: () => _cropController.rotateLeft(),
                  ),
                  const SizedBox(width: 16),
                  IconButton.outlined(
                    icon: const Icon(Icons.rotate_right),
                    tooltip: 'Повернуть вправо',
                    onPressed: () => _cropController.rotateRight(),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SmoothButton(
                      label: 'Отмена',
                      type: SmoothButtonType.outlined,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmoothButton(
                      label: 'Применить',
                      type: SmoothButtonType.filled,
                      isFullWidth: true,
                      loading: _isProcessing,
                      onPressed: _applyCrop,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyCrop() async {
    setState(() => _isProcessing = true);

    try {
      final croppedImage = await _cropController.croppedBitmap();
      if (mounted) {
        Navigator.of(context).pop(croppedImage);
      }
    } catch (e) {
      if (mounted) {
        Toaster.error(title: 'Ошибка обрезки', description: e.toString());
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Button for selecting aspect ratio
class _AspectRatioButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AspectRatioButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Function to decode QR code in isolate to avoid blocking UI
String? _decodeQrCodeInIsolate(Uint8List bytes) {
  try {
    final image = img.decodeImage(bytes);

    if (image == null) {
      return null;
    }

    // Convert image to ABGR format for zxing2
    final convertedImage = image.convert(numChannels: 4);
    final int32List = convertedImage
        .getBytes(order: img.ChannelOrder.abgr)
        .buffer
        .asInt32List();

    final source = RGBLuminanceSource(image.width, image.height, int32List);

    final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
    final reader = QRCodeReader();

    try {
      final result = reader.decode(bitmap);
      return result.text;
    } on NotFoundException {
      // Try with HybridBinarizer as fallback
      final hybridBitmap = BinaryBitmap(HybridBinarizer(source));
      try {
        final result = reader.decode(hybridBitmap);
        return result.text;
      } on NotFoundException {
        return null;
      }
    }
  } catch (e) {
    return null;
  }
}
