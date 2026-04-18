import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_packs_state.dart';
import 'package:hoplixi/features/custom_icon_packs/services/icon_pack_catalog_service.dart';

final iconPackCatalogServiceProvider = Provider<IconPackCatalogService>((ref) {
  return const IconPackCatalogService();
});

class IconPacksNotifier extends Notifier<IconPacksState> {
  @override
  IconPacksState build() {
    Future.microtask(loadPacks);
    return const IconPacksState();
  }

  Future<void> loadPacks() async {
    state = state.copyWith(isLoadingPacks: true, errorMessage: null);
    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      final packs = await service.listPacks();
      state = state.copyWith(isLoadingPacks: false, packs: packs);
    } on IconPackCatalogException catch (error) {
      state = state.copyWith(
        isLoadingPacks: false,
        errorMessage: error.message,
      );
    } catch (error, stackTrace) {
      logError(
        'Failed to load icon packs: $error',
        tag: 'IconPacksNotifier',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingPacks: false,
        errorMessage: 'Не удалось загрузить список паков.',
      );
    }
  }

  Future<FilePickerResult?> pickArchiveFile() {
    return FilePicker.pickFiles(
      dialogTitle: 'Выберите ZIP-архив с SVG-иконками',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
  }

  Future<String?> pickSourceDirectory() {
    return FilePicker.getDirectoryPath(
      dialogTitle: 'Выберите папку с SVG-иконками',
    );
  }

  void setImportDraft({
    required String sourcePath,
    required IconPackImportSourceType sourceType,
    required String displayName,
  }) {
    final sanitizedDisplayName = displayName.trim();
    final packKey = IconPackCatalogService.normalizePackKey(
      sanitizedDisplayName,
    );

    state = state.copyWith(
      selectedSourcePath: sourcePath,
      sourceType: sourceType,
      displayName: sanitizedDisplayName,
      packKey: packKey,
      errorMessage: null,
      successMessage: null,
      progress: 0,
      currentFile: null,
    );
  }

  void clearImportDraft() {
    state = state.copyWith(
      selectedSourcePath: null,
      sourceType: null,
      displayName: null,
      packKey: null,
      progress: 0,
      currentFile: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  void clearFeedback() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  bool packKeyExists(String packKey) {
    final normalized = packKey.trim().toLowerCase();
    return state.packs.any((pack) => pack.packKey == normalized);
  }

  Future<void> importSelectedPack() async {
    final sourcePath = state.selectedSourcePath;
    final sourceType = state.sourceType;
    final displayName = state.displayName;
    final packKey = state.packKey;
    if (sourcePath == null ||
        sourceType == null ||
        displayName == null ||
        displayName.trim().isEmpty ||
        packKey == null ||
        packKey.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Сначала выберите источник и название пака.',
      );
      return;
    }

    state = state.copyWith(
      isImporting: true,
      progress: 0,
      currentFile: null,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      final importedPack = switch (sourceType) {
        IconPackImportSourceType.archive => await service.importPack(
          archivePath: sourcePath,
          displayName: displayName,
          onProgress: (current, total, currentFile) {
            state = state.copyWith(
              progress: total == 0 ? 0 : current / total,
              currentFile: currentFile,
            );
          },
        ),
        IconPackImportSourceType.directory => await service.importDirectory(
          directoryPath: sourcePath,
          displayName: displayName,
          onProgress: (current, total, currentFile) {
            state = state.copyWith(
              progress: total == 0 ? 0 : current / total,
              currentFile: currentFile,
            );
          },
        ),
      };

      final packs = await service.listPacks();
      state = state.copyWith(
        packs: packs,
        isImporting: false,
        progress: 1,
        successMessage:
            'Пак "${importedPack.displayName}" успешно импортирован.',
      );
    } on IconPackCatalogException catch (error) {
      state = state.copyWith(isImporting: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      logError(
        'Failed to import selected icon pack: $error',
        tag: 'IconPacksNotifier',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isImporting: false,
        errorMessage: 'Не удалось импортировать пак иконок.',
      );
    }
  }
}

final iconPacksNotifierProvider =
    NotifierProvider.autoDispose<IconPacksNotifier, IconPacksState>(
      IconPacksNotifier.new,
    );
