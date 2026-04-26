import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';

part 'db_state.freezed.dart';

enum DatabaseStatus {
  idle, // База данных не открыта, нет активной сессии
  opening, // Процесс открытия базы данных (асинхронный)
  open, // База данных успешно открыта, активная сессия существует
  locked, // База данных заблокирована сессия уничтожена, требуется повторная аутентификация для открытия
  loading, // Процесс загрузки данных из базы данных (асинхронный)
  closingSync, // Процесс синхронизации cloud sync при закрытии базы данных (асинхронный)
  closed, // База данных закрыта, сессия уничтожена
  error, // Произошла ошибка при открытии, загрузке или синхронизации базы данных
}

@freezed
sealed class DatabaseState with _$DatabaseState {
  const factory DatabaseState({
    String?
    path, // Путь к директории хранилища, может быть null, если БД не открыта
    StoreInfoDto? info, // Информация о хранилище, null если БД не открыта
    @Default(DatabaseStatus.closed) DatabaseStatus status,
    AppError? error,
    DateTime? modifiedAt,
  }) = _DatabaseState;

  const DatabaseState._();

  bool get isIdle => status == DatabaseStatus.idle;
  bool get isOpening => status == DatabaseStatus.opening;
  bool get isOpen => status == DatabaseStatus.open;
  bool get isClosed => status == DatabaseStatus.closed;
  bool get isLocked => status == DatabaseStatus.locked;
  bool get isLoading => status == DatabaseStatus.loading;
  bool get isClosingSync => status == DatabaseStatus.closingSync;
  bool get hasError => status == DatabaseStatus.error;
}
