import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_state.freezed.dart';

/// Состояние передачи данных.
@freezed
sealed class TransferState with _$TransferState {
  /// Ожидание действий пользователя.
  const factory TransferState.idle() = TransferIdle;

  /// Подготовка к передаче (выбор файлов).
  const factory TransferState.preparing() = TransferPreparing;

  /// Ожидание подтверждения от получателя.
  const factory TransferState.waitingApproval() = TransferWaitingApproval;

  /// Установка WebRTC-соединения.
  const factory TransferState.connecting() = TransferConnecting;

  /// Передача данных в процессе.
  const factory TransferState.transferring({
    /// Общий прогресс от 0.0 до 1.0.
    required double progress,

    /// Имя текущего файла.
    required String currentFile,

    /// Индекс текущего файла (0-based).
    required int currentIndex,

    /// Общее количество файлов.
    required int totalFiles,
  }) = TransferTransferring;

  /// Передача завершена успешно.
  const factory TransferState.completed() = TransferCompleted;

  /// Получатель отклонил запрос.
  const factory TransferState.rejected() = TransferRejected;

  /// Передача отменена.
  const factory TransferState.cancelled() = TransferCancelled;

  /// Ошибка.
  const factory TransferState.error({required String message}) = TransferError;
}
