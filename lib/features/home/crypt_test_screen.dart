import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/rust/api/crypt_api.dart';

class CryptTestScreen extends ConsumerStatefulWidget {
  const CryptTestScreen({super.key});

  @override
  ConsumerState<CryptTestScreen> createState() => _CryptTestScreenState();
}

class _CryptTestScreenState extends ConsumerState<CryptTestScreen> {
  final _passwordController = TextEditingController();
  String? _selectedFilePath;
  String? _outputFilePath;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _headerInfo;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _outputFilePath = null;
        _statusMessage =
            'Файл выбран: ${_selectedFilePath!.split(Platform.pathSeparator).last}';
        _headerInfo = null;
        _progress = 0.0;
      });
    }
  }

  Future<void> _encrypt() async {
    if (_selectedFilePath == null || _passwordController.text.isEmpty) {
      _showError('Выберите файл и введите пароль');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = 'Шифрование...';
    });

    try {
      final outputDir = File(_selectedFilePath!).parent.path;
      final opts = await FrbEncryptOptions.simple(
        inputPath: _selectedFilePath!,
        outputDir: outputDir,
        password: _passwordController.text,
      );

      final stream = encryptFile(opts: opts);

      await runZonedGuarded(
        () => stream
            .listen(
              (event) {
                event.when(
                  progress: (progress) {
                    setState(() {
                      _progress = progress.percentage / 100.0;
                    });
                  },
                  done: (result) {
                    setState(() {
                      _outputFilePath = result.outputPath;
                      _statusMessage =
                          'Успешно зашифровано в:\n${result.outputPath}';
                      _isProcessing = false;
                      _progress = 1.0;
                    });
                  },
                  error: (e) {
                    _showError('Ошибка шифрования: $e');
                    setState(() => _isProcessing = false);
                  },
                );
              },
              onError: (Object e) {
                _showError('Ошибка шифрования: $e');
                setState(() => _isProcessing = false);
              },
              cancelOnError: true,
            )
            .asFuture<void>(),
        (e, _) {
          _showError('Ошибка шифрования: $e');
          setState(() => _isProcessing = false);
        },
      );
    } catch (e) {
      _showError('Ошибка шифрования: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _decrypt() async {
    if (_selectedFilePath == null || _passwordController.text.isEmpty) {
      _showError('Выберите файл и введите пароль');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = 'Дешифрование...';
    });

    try {
      final outputDir = File(_selectedFilePath!).parent.path;
      final opts = await FrbDecryptOptions.simple(
        inputPath: _selectedFilePath!,
        outputDir: outputDir,
        password: _passwordController.text,
      );

      final stream = decryptFile(opts: opts);

      await runZonedGuarded(
        () => stream
            .listen(
              (event) {
                event.when(
                  progress: (progress) {
                    setState(() {
                      _progress = progress.percentage / 100.0;
                    });
                  },
                  done: (result) {
                    setState(() {
                      _outputFilePath = result.outputPath;
                      _statusMessage =
                          'Успешно расшифровано в:\n${result.outputPath}';
                      _isProcessing = false;
                      _progress = 1.0;
                    });
                  },
                  error: (error) {
                    _showError('Ошибка дешифрования: $error');
                    setState(() => _isProcessing = false);
                  },
                );
              },
              onError: (Object e) {
                _showError('Ошибка дешифрования: $e');
                setState(() => _isProcessing = false);
              },
              cancelOnError: true,
            )
            .asFuture<void>(),
        (e, _) {
          _showError('Ошибка дешифрования: $e');
          setState(() => _isProcessing = false);
        },
      );
    } catch (e) {
      _showError('Ошибка дешифрования: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _readHeader() async {
    if (_selectedFilePath == null || _passwordController.text.isEmpty) {
      _showError('Выберите файл и введите пароль');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Чтение заголовка...';
    });

    try {
      final meta = await readEncryptedHeader(
        inputPath: _selectedFilePath!,
        password: _passwordController.text,
      );
      setState(() {
        _headerInfo =
            'Имя файла: ${meta.originalFilename}\n'
            'Расширение: ${meta.originalExtension}\n'
            'UUID: ${meta.uuid}\n'
            'Размер: ${meta.originalSize} байт\n'
            'Gzip: ${meta.gzipCompressed ? "Да" : "Нет"}\n'
            'Метаданные: ${meta.metadata.length} записей';
        _statusMessage = 'Заголовок прочитан';
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Ошибка чтения заголовка: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тест шифрования файлов')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Файл',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedFilePath ?? 'Файл не выбран',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _selectedFilePath == null
                                      ? Theme.of(context).colorScheme.outline
                                      : null,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _pickFile,
                          icon: const Icon(LucideIcons.file_search),
                          label: const Text('Выбрать'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.key),
              ),
              obscureText: true,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _encrypt,
                  icon: const Icon(LucideIcons.lock),
                  label: const Text('Зашифровать'),
                ),
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _decrypt,
                  icon: const Icon(LucideIcons.lock_keyhole_open),
                  label: const Text('Расшифровать'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _readHeader,
                icon: const Icon(LucideIcons.info),
                label: const Text('Прочитать заголовок'),
              ),
            ),
            const SizedBox(height: 32),
            if (_isProcessing || _progress > 0) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_headerInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация из заголовка:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_headerInfo!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
