import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_packs_state.dart';
import 'package:hoplixi/features/custom_icon_packs/services/icon_pack_catalog_service.dart';

final iconPackCatalogServiceProvider = Provider<IconPackCatalogService>((ref) {
  return const IconPackCatalogService();
});

const _importProgressUiInterval = Duration(milliseconds: 120);
const _importProgressDelta = 0.01;

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
      dialogTitle: 'Выберите ZIP- или 7Z-архив с SVG-иконками',
      type: FileType.custom,
      allowedExtensions: const ['zip', '7z'],
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

  Future<void> deletePack(String packKey) async {
    if (state.isImporting || state.deletingPackKey != null) {
      return;
    }

    state = state.copyWith(
      deletingPackKey: packKey,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final service = ref.read(iconPackCatalogServiceProvider);
      await service.deletePack(packKey);
      state = state.copyWith(
        packs: state.packs
            .where((pack) => pack.packKey != packKey)
            .toList(growable: false),
        deletingPackKey: null,
        successMessage: 'Пак иконок удалён.',
      );
      Future.microtask(loadPacks);
    } on IconPackCatalogException catch (error) {
      state = state.copyWith(
        deletingPackKey: null,
        errorMessage: error.message,
      );
    } catch (error, stackTrace) {
      logError(
        'Failed to delete icon pack: $error',
        tag: 'IconPacksNotifier',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        deletingPackKey: null,
        errorMessage: 'Не удалось удалить пак иконок.',
      );
    }
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
      var lastProgressUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      var lastProgressValue = 0.0;

      void updateImportProgress(int current, int total, String currentFile) {
        final nextProgress = _progressValue(current, total);
        final now = DateTime.now();
        final isFinal = total > 0 && current >= total;
        final shouldUpdate =
            isFinal ||
            nextProgress - lastProgressValue >= _importProgressDelta ||
            now.difference(lastProgressUpdate) >= _importProgressUiInterval;

        if (!shouldUpdate) {
          return;
        }

        lastProgressUpdate = now;
        lastProgressValue = nextProgress;
        state = state.copyWith(progress: nextProgress, currentFile: currentFile);
      }

      final importedPack = switch (sourceType) {
        IconPackImportSourceType.archive => await service.importPack(
          archivePath: sourcePath,
          displayName: displayName,
          onProgress: updateImportProgress,
        ),
        IconPackImportSourceType.directory => await service.importDirectory(
          directoryPath: sourcePath,
          displayName: displayName,
          onProgress: updateImportProgress,
        ),
      };

      final packs = [
        importedPack,
        ...state.packs.where((pack) => pack.packKey != importedPack.packKey),
      ]..sort((left, right) => right.importedAt.compareTo(left.importedAt));
      state = state.copyWith(
        packs: packs,
        isImporting: false,
        progress: 1,
        currentFile: null,
        successMessage:
            'Пак "${importedPack.displayName}" успешно импортирован.',
      );
      Future.microtask(loadPacks);
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

  double _progressValue(int current, int total) {
    if (total <= 0) {
      return 0;
    }

    return (current / total).clamp(0, 1).toDouble();
  }
}

final iconPacksNotifierProvider =
    NotifierProvider.autoDispose<IconPacksNotifier, IconPacksState>(
      IconPacksNotifier.new,
    );
