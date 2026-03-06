import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';

part 'session_state.freezed.dart';

/// Состояние сессии обмена данными между устройствами.
@freezed
sealed class SessionState with _$SessionState {
  /// Нет активной сессии — показываем список устройств.
  const factory SessionState.disconnected() = SessionDisconnected;

  /// Ожидание подтверждения от удалённого устройства.
  const factory SessionState.waitingApproval({required DeviceInfo peer}) =
      SessionWaitingApproval;

  /// Установка WebRTC-соединения.
  const factory SessionState.connecting({required DeviceInfo peer}) =
      SessionConnecting;

  /// Активная сессия — можно обмениваться файлами и текстом.
  const factory SessionState.connected({required DeviceInfo peer}) =
      SessionConnected;

  /// Идёт передача файла.
  const factory SessionState.transferring({
    required DeviceInfo peer,

    /// Прогресс от 0.0 до 1.0.
    required double progress,

    /// Имя текущего файла.
    required String currentFile,

    /// Индекс текущего файла (0-based).
    required int currentIndex,

    /// Общее количество файлов.
    required int totalFiles,

    /// true = отправляем, false = получаем.
    required bool isSending,
  }) = SessionTransferring;

  /// Ошибка.
  const factory SessionState.error({required String message}) = SessionError;
}
