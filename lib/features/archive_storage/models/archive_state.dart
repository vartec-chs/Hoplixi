import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/main_db/models/store_folder_info.dart';


part 'archive_state.freezed.dart';

/// Состояние экрана архивации
@freezed
sealed class ArchiveScreenState with _$ArchiveScreenState {
  const factory ArchiveScreenState({
    /// Список доступных хранилищ
    @Default([]) List<StoreFolderInfo> availableStores,

    /// Загружается ли список хранилищ
    @Default(false) bool isLoadingStores,

    /// Выбранное хранилище для экспорта
    StoreFolderInfo? selectedStore,

    /// Путь для сохранения архива
    String? exportPath,

    /// Пароль для архива
    String? password,

    /// Прогресс архивации (0.0 - 1.0)
    @Default(0.0) double progress,

    /// Текущий обрабатываемый файл
    String? currentFile,

    /// Идёт ли процесс архивации
    @Default(false) bool isArchiving,

    /// Ошибка архивации
    AppError? error,

    /// Путь к архиву для импорта
    String? importPath,

    /// Заменять локальное хранилище, если архив новее по manifest.
    @Default(false) bool replaceExistingIfNewer,

    /// Идёт ли процесс разархивации
    @Default(false) bool isUnarchiving,

    /// Успешно завершена операция
    @Default(false) bool isSuccess,

    /// Сообщение об успехе
    String? successMessage,
  }) = _ArchiveScreenState;
}
