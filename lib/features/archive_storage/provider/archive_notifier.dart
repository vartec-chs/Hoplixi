import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/archive_storage/models/archive_state.dart';
import 'package:hoplixi/main_store/models/store_folder_info.dart';
import 'package:hoplixi/main_store/provider/archive_provider.dart';
import 'package:path/path.dart' as p;

/// Провайдер для управления состоянием экрана архивации
class ArchiveNotifier extends Notifier<ArchiveScreenState> {
  @override
  ArchiveScreenState build() {
    // Загружаем данные асинхронно, чтобы избежать циклической зависимости
    Future.microtask(() => _loadStores());
    return const ArchiveScreenState();
  }

  /// Загрузка списка доступных хранилищ
  Future<void> _loadStores() async {
    state = state.copyWith(isLoadingStores: true);
    try {
      final stores = await AppPaths.getAllStorageFolders();
      state = state.copyWith(availableStores: stores, isLoadingStores: false);
    } catch (e) {
      logError('Ошибка при загрузке хранилищ: $e', tag: 'ArchiveNotifier');
      state = state.copyWith(isLoadingStores: false);
    }
  }

  /// Выбор хранилища для экспорта
  void selectStore(StoreFolderInfo? store) {
    state = state.copyWith(selectedStore: store, error: null, isSuccess: false);
  }

  /// Установка пароля
  void setPassword(String? password) {
    state = state.copyWith(password: password);
  }

  /// Выбор пути для сохранения архива
  Future<void> pickExportPath() async {
    try {
      final selectedStore = state.selectedStore;
      if (selectedStore == null) return;

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Выберите куда сохранить архив',
        fileName: '${selectedStore.storeName}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        state = state.copyWith(exportPath: result);
      }
    } catch (e) {
      logError('Ошибка при выборе пути экспорта: $e', tag: 'ArchiveNotifier');
    }
  }

  /// Экспорт хранилища
  Future<void> exportStore() async {
    final selectedStore = state.selectedStore;
    final exportPath = state.exportPath;

    if (selectedStore == null || exportPath == null) return;

    state = state.copyWith(
      isArchiving: true,
      progress: 0.0,
      error: null,
      isSuccess: false,
    );

    try {
      final archiveService = ref.read(archiveServiceProvider);

      final result = await archiveService.archiveStore(
        selectedStore.folderPath,
        exportPath,
        password: state.password,
        onProgress: (current, total, fileName) {
          state = state.copyWith(
            progress: current / total,
            currentFile: fileName,
          );
        },
      );

      result.fold(
        (success) {
          state = state.copyWith(
            isArchiving: false,
            isSuccess: true,
            successMessage: 'Хранилище успешно экспортировано в $exportPath',
            progress: 1.0,
          );
          logInfo('Экспорт завершён: $exportPath', tag: 'ArchiveNotifier');
        },
        (error) {
          state = state.copyWith(isArchiving: false, error: error);
          logError('Ошибка экспорта: ${error.message}', tag: 'ArchiveNotifier');
        },
      );
    } catch (e) {
      logError('Неожиданная ошибка экспорта: $e', tag: 'ArchiveNotifier');
      state = state.copyWith(isArchiving: false);
    }
  }

  /// Выбор файла архива для импорта
  Future<void> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Выберите архив для импорта',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          importPath: result.files.single.path,
          error: null,
          isSuccess: false,
        );
      }
    } catch (e) {
      logError('Ошибка при выборе файла импорта: $e', tag: 'ArchiveNotifier');
    }
  }

  /// Импорт хранилища
  Future<void> importStore() async {
    final importPath = state.importPath;
    if (importPath == null) return;

    state = state.copyWith(
      isUnarchiving: true,
      progress: 0.0,
      error: null,
      isSuccess: false,
    );

    try {
      final archiveService = ref.read(archiveServiceProvider);

      final result = await archiveService.unarchiveStore(
        importPath,
        password: state.password,
        onProgress: (current, total, fileName) {
          state = state.copyWith(
            progress: current / total,
            currentFile: fileName,
          );
        },
      );

      result.fold(
        (extractedPath) {
          state = state.copyWith(
            isUnarchiving: false,
            isSuccess: true,
            successMessage:
                'Хранилище успешно импортировано в ${p.basename(extractedPath)}',
            progress: 1.0,
          );
          logInfo('Импорт завершён: $extractedPath', tag: 'ArchiveNotifier');
          // Перезагружаем список хранилищ
          _loadStores();
        },
        (error) {
          state = state.copyWith(isUnarchiving: false, error: error);
          logError('Ошибка импорта: ${error.message}', tag: 'ArchiveNotifier');
        },
      );
    } catch (e) {
      logError('Неожиданная ошибка импорта: $e', tag: 'ArchiveNotifier');
      state = state.copyWith(isUnarchiving: false);
    }
  }

  /// Сброс состояния
  void reset() {
    state = const ArchiveScreenState();
    _loadStores();
  }

  /// Очистка результатов операции (для начала новой операции)
  void clearResults() {
    state = state.copyWith(
      error: null,
      isSuccess: false,
      successMessage: null,
      progress: 0.0,
      currentFile: null,
      exportPath: null,
      importPath: null,
      password: null,
    );
  }
}

final archiveNotifierProvider =
    NotifierProvider.autoDispose<ArchiveNotifier, ArchiveScreenState>(
      ArchiveNotifier.new,
    );
