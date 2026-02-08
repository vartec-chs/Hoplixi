import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/provider/service_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';
import 'package:open_file/open_file.dart';
import 'package:watcher/watcher.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

void showFileDecryptModal(BuildContext context, FileCardDto file) {
  WoltModalSheet.show(
    context: context,
    useRootNavigator: true,

    pageListBuilder: (context) {
      return [
        WoltModalSheetPage(
          hasSabGradient: false,
          topBarTitle: Text(
            'Расшифровка файла',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          isTopBarLayerAlwaysVisible: true,
          child: _FileDecryptContent(file: file),
        ),
      ];
    },
  );
}

class _FileDecryptContent extends ConsumerStatefulWidget {
  final FileCardDto file;

  const _FileDecryptContent({required this.file});

  @override
  ConsumerState<_FileDecryptContent> createState() =>
      _FileDecryptContentState();
}

class _FileDecryptContentState extends ConsumerState<_FileDecryptContent> {
  bool _isDecrypting = false;
  bool _isUpdating = false;
  bool _isFileModified = false;
  String? _decryptedFilePath;
  String? _error;
  StreamSubscription<WatchEvent>? _fileWatcher;

  @override
  void dispose() {
    _fileWatcher?.cancel();
    _deleteDecryptedFile();
    super.dispose();
  }

  Future<void> _deleteDecryptedFile() async {
    if (_decryptedFilePath != null) {
      final file = File(_decryptedFilePath!);
      if (await file.exists()) {
        try {
          await file.delete();
          logInfo(
            "Deleted decrypted file: $_decryptedFilePath",
            tag: 'FileDecryptModal',
          );
          Toaster.info(title: 'Временный файл удален');
        } catch (e, st) {
          Toaster.error(
            title: 'Ошибка удаления файла',
            description:
                'Не удалось удалить временный файл по пути $_decryptedFilePath. Попробуйте удалить его вручную.',
          );
          logError(
            "Failed to delete decrypted file: $_decryptedFilePath",
            tag: 'FileDecryptModal',
            stackTrace: st,
            error: e,
          );
        }
      }
    }
  }

  Future<void> _decryptFile() async {
    setState(() {
      _isDecrypting = true;
      _error = null;
    });

    try {
      final storageService = await ref.read(fileStorageServiceProvider.future);

      final decryptedFilePath = await storageService.decryptFile(
        fileId: widget.file.id,
      );

      if (mounted) {
        setState(() {
          _decryptedFilePath = decryptedFilePath;
          _isDecrypting = false;
        });
        _setupFileWatcher(decryptedFilePath);
        Toaster.success(title: 'Файл успешно расшифрован');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDecrypting = false;
        });
        Toaster.error(title: 'Ошибка расшифровки', description: e.toString());
      }
    }
  }

  void _setupFileWatcher(String path) {
    _fileWatcher?.cancel();
    _fileWatcher = FileWatcher(path).events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        if (mounted) {
          setState(() {
            _isFileModified = true;
          });
        }
      }
    });
  }

  Future<void> _updateFile() async {
    if (_decryptedFilePath == null) return;

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      final storageService = await ref.read(fileStorageServiceProvider.future);
      final file = File(_decryptedFilePath!);

      await storageService.updateFileContent(
        fileId: widget.file.id,
        newFile: file,
      );

      if (mounted) {
        setState(() {
          _isUpdating = false;
          _isFileModified = false;
        });
        Toaster.success(title: 'Файл успешно обновлен');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isUpdating = false;
        });
        Toaster.error(title: 'Ошибка обновления', description: e.toString());
      }
    }
  }

  Future<void> _openFile() async {
    if (_decryptedFilePath != null) {
      await OpenFile.open(_decryptedFilePath);
    }
  }

  Future<void> _deleteAndClose() async {
    await _deleteDecryptedFile();
    if (mounted) {
      setState(() {
        _decryptedFilePath = null;
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NotificationCard(
            type: .warning,
            text:
                'Не закрывайте это окно, пока не закончите работу с расшифрованным файлом для безопасности. В противном случае временный файл будет принудительно удален.',
          ),
          const SizedBox(height: 16),
          // Информация о файле
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.file.fileName ?? '',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),

            child: _isFileModified
                ? Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const NotificationCard(
                        type: .info,
                        text:
                            'Файл был изменен. Протяните "Обновить файл", чтобы сохранить изменения в хранилище.',
                      ),
                      const SizedBox(height: 16),
                      SliderButton(
                        type: SliderButtonType.confirm,
                        text: 'Обновить файл',
                        onSlideCompleteAsync: _updateFile,
                        showLoading: _isUpdating,
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Кнопки действий
          if (_decryptedFilePath == null) ...[
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Расшифровать',
                onPressed: _isDecrypting ? null : _decryptFile,
                loading: _isDecrypting,
                icon: const Icon(Icons.lock_open),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Открыть файл',
                onPressed: _openFile,
                icon: const Icon(Icons.open_in_new),
                variant: SmoothButtonVariant.success,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Удалить расшифрованный файл',
                onPressed: _deleteAndClose,
                icon: const Icon(Icons.delete_forever),
                variant: SmoothButtonVariant.error,
                type: SmoothButtonType.outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
