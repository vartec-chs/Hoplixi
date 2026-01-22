import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Экран демонстрации компонента Document Scanner
class DocumentScannerShowcaseScreen extends StatefulWidget {
  const DocumentScannerShowcaseScreen({super.key});

  @override
  State<DocumentScannerShowcaseScreen> createState() =>
      _DocumentScannerShowcaseScreenState();
}

class _DocumentScannerShowcaseScreenState
    extends State<DocumentScannerShowcaseScreen> {
  dynamic _scannedDocuments;
  String _statusMessage = 'Готов к сканированию';

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _statusMessage = 'Разрешение на камеру получено';
    } else if (status.isDenied) {
      _statusMessage = 'Разрешение на камеру отклонено';
    } else if (status.isPermanentlyDenied) {
      _statusMessage =
          'Разрешение на камеру permanently denied. Откройте настройки.';
      await openAppSettings();
    }
    setState(() {});
  }

  Future<void> _scanDocument() async {
    await _requestCameraPermission();
    final status = await Permission.camera.status;
    if (!status.isGranted) return;

    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScanDocuments(page: 4) ??
          'Неизвестные документы платформы';
      _statusMessage = 'Документы отсканированы успешно';
    } on PlatformException {
      scannedDocuments = 'Не удалось получить отсканированные документы.';
      _statusMessage = 'Ошибка сканирования';
    }
    print(scannedDocuments.toString());
    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
    });
  }

  Future<void> _scanDocumentAsImages() async {
    await _requestCameraPermission();
    final status = await Permission.camera.status;
    if (!status.isGranted) return;

    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScannedDocumentAsImages(page: 4) ??
          'Неизвестные документы платформы';
      _statusMessage = 'Документы отсканированы как изображения';
    } on PlatformException {
      scannedDocuments = 'Не удалось получить отсканированные документы.';
      _statusMessage = 'Ошибка сканирования';
    }
    print(scannedDocuments.toString());
    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
    });
  }

  Future<void> _scanDocumentAsPdf() async {
    await _requestCameraPermission();
    final status = await Permission.camera.status;
    if (!status.isGranted) return;

    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScannedDocumentAsPdf(page: 4) ??
          'Неизвестные документы платформы';
      _statusMessage = 'Документы отсканированы как PDF';
    } on PlatformException {
      scannedDocuments = 'Не удалось получить отсканированные документы.';
      _statusMessage = 'Ошибка сканирования';
    }
    print(scannedDocuments.toString());
    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
    });
  }

  Future<void> _scanDocumentUri() async {
    // Эта функция поддерживается только для Android
    await _requestCameraPermission();
    final status = await Permission.camera.status;
    if (!status.isGranted) return;

    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScanDocumentsUri(page: 4) ??
          'Неизвестные документы платформы';
      _statusMessage = 'URI документов получены';
    } on PlatformException {
      scannedDocuments = 'Не удалось получить URI документов.';
      _statusMessage = 'Ошибка получения URI';
    }
    print(scannedDocuments.toString());
    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Статус и Результат',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статус: $_statusMessage',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Результат: ${_scannedDocuments?.toString() ?? 'Нет результатов'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Методы сканирования',
          children: [
            _buildButton(
              context,
              label: 'Сканировать документы',
              onPressed: _scanDocument,
              description: 'Получить отсканированные документы',
            ),
            const SizedBox(height: 12),
            _buildButton(
              context,
              label: 'Сканировать как изображения',
              onPressed: _scanDocumentAsImages,
              description: 'Получить документы как изображения',
            ),
            const SizedBox(height: 12),
            _buildButton(
              context,
              label: 'Сканировать как PDF',
              onPressed: _scanDocumentAsPdf,
              description: 'Получить документы как PDF',
            ),
            const SizedBox(height: 12),
            _buildButton(
              context,
              label: 'Получить URI документов',
              onPressed: _scanDocumentUri,
              description: 'Получить URI документов (только Android)',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Информация',
          children: [
            Text(
              'Этот компонент использует flutter_doc_scanner для сканирования документов с камеры. '
              'Перед сканированием запрашивается разрешение на использование камеры через permission_handler.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: onPressed, child: Text(label)),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
