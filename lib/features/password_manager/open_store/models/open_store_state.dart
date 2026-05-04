import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';

part 'open_store_state.freezed.dart';

/// Состояние экрана открытия хранилища
@freezed
sealed class OpenStoreState with _$OpenStoreState {
  const factory OpenStoreState({
    /// Список доступных хранилищ
    @Default([]) List<StorageInfo> storages,

    /// Выбранное хранилище
    StorageInfo? selectedStorage,

    /// Пароль для открытия
    @Default('') String password,

    /// Флаг процесса открытия
    @Default(false) bool isOpening,

    /// Флаг загрузки списка хранилищ
    @Default(false) bool isLoading,

    /// Ошибка при вводе пароля
    String? passwordError,

    /// Key file выбранный для открытия текущего хранилища.
    String? keyFileId,
    String? keyFileHint,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Uint8List? keyFileSecret,
    String? keyFileError,

    /// Общая ошибка
    String? error,

    /// OAuth токены, сгруппированные по провайдеру
    @Default(<CloudSyncProvider, List<AuthTokenEntry>>{})
    Map<CloudSyncProvider, List<AuthTokenEntry>> cloudTokensByProvider,

    /// Выбранный провайдер для импорта снапшота
    CloudSyncProvider? selectedCloudProvider,

    /// Выбранный OAuth токен
    String? selectedCloudTokenId,

    /// Доступные remote stores для выбранного токена
    @Default(<CloudManifestStoreEntry>[])
    List<CloudManifestStoreEntry> remoteSnapshots,

    /// Идёт загрузка cloud manifest
    @Default(false) bool isLoadingRemoteSnapshots,

    /// Ошибка загрузки remote snapshots
    String? remoteSnapshotsError,

    /// Store UUID, который сейчас импортируется
    String? downloadingRemoteStoreUuid,

    /// Запрос на привязку только что импортированного локального store
    PendingImportedStoreBinding? pendingImportedStoreBinding,
  }) = _OpenStoreState;
}

class PendingImportedStoreBinding {
  const PendingImportedStoreBinding({
    required this.localStoreUuid,
    required this.localStoreName,
    required this.localStoragePath,
    required this.remoteStoreUuid,
    required this.tokenId,
    required this.provider,
    required this.accountLabel,
  });

  final String localStoreUuid;
  final String localStoreName;
  final String localStoragePath;
  final String remoteStoreUuid;
  final String tokenId;
  final CloudSyncProvider provider;
  final String accountLabel;

  String get promptDescription =>
      'Привязать "$localStoreName" к ${provider.metadata.displayName} ($accountLabel), '
      'чтобы дальше использовать cloud sync для этого store?';
}

/// Информация о хранилище
@freezed
sealed class StorageInfo with _$StorageInfo {
  const factory StorageInfo({
    /// Имя хранилища
    required String name,

    /// Полный путь к файлу базы данных
    required String path,

    /// Дата последнего изменения
    required DateTime modifiedAt,

    /// Описание (опционально)
    String? description,

    /// Размер файла в байтах
    int? size,

    /// Из истории или из папки
    @Default(false) bool fromHistory,

    /// Последнее время открытия (для истории)
    DateTime? lastOpenedAt,
  }) = _StorageInfo;

  const StorageInfo._();

  /// Форматированный размер файла
  String get formattedSize {
    if (size == null) return 'Неизвестно';
    final kb = size! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  /// Форматированная дата изменения
  String get formattedModifiedDate {
    final now = DateTime.now();
    final difference = now.difference(modifiedAt);

    if (difference.inMinutes < 1) return 'Только что';
    if (difference.inHours < 1) return '${difference.inMinutes} мин назад';
    if (difference.inDays < 1) return '${difference.inHours} ч назад';
    if (difference.inDays < 7) return '${difference.inDays} дн назад';

    return '${modifiedAt.day}.${modifiedAt.month}.${modifiedAt.year}';
  }
}
