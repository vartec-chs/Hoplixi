import 'icon_pack_summary.dart';

enum IconPackImportSourceType { archive, directory }

class IconPacksState {
  const IconPacksState({
    this.packs = const [],
    this.isLoadingPacks = false,
    this.isImporting = false,
    this.deletingPackKey,
    this.selectedSourcePath,
    this.sourceType,
    this.displayName,
    this.packKey,
    this.progress = 0,
    this.currentFile,
    this.errorMessage,
    this.successMessage,
  });

  final List<IconPackSummary> packs;
  final bool isLoadingPacks;
  final bool isImporting;
  final String? deletingPackKey;
  final String? selectedSourcePath;
  final IconPackImportSourceType? sourceType;
  final String? displayName;
  final String? packKey;
  final double progress;
  final String? currentFile;
  final String? errorMessage;
  final String? successMessage;

  bool get canImport =>
      !isImporting &&
      deletingPackKey == null &&
      selectedSourcePath != null &&
      sourceType != null &&
      displayName != null &&
      displayName!.trim().isNotEmpty &&
      packKey != null &&
      packKey!.trim().isNotEmpty;

  IconPacksState copyWith({
    List<IconPackSummary>? packs,
    bool? isLoadingPacks,
    bool? isImporting,
    Object? deletingPackKey = _unset,
    Object? selectedSourcePath = _unset,
    Object? sourceType = _unset,
    Object? displayName = _unset,
    Object? packKey = _unset,
    double? progress,
    Object? currentFile = _unset,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
  }) {
    return IconPacksState(
      packs: packs ?? this.packs,
      isLoadingPacks: isLoadingPacks ?? this.isLoadingPacks,
      isImporting: isImporting ?? this.isImporting,
      deletingPackKey: identical(deletingPackKey, _unset)
          ? this.deletingPackKey
          : deletingPackKey as String?,
      selectedSourcePath: identical(selectedSourcePath, _unset)
          ? this.selectedSourcePath
          : selectedSourcePath as String?,
      sourceType: identical(sourceType, _unset)
          ? this.sourceType
          : sourceType as IconPackImportSourceType?,
      displayName: identical(displayName, _unset)
          ? this.displayName
          : displayName as String?,
      packKey: identical(packKey, _unset) ? this.packKey : packKey as String?,
      progress: progress ?? this.progress,
      currentFile: identical(currentFile, _unset)
          ? this.currentFile
          : currentFile as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  static const _unset = Object();
}
