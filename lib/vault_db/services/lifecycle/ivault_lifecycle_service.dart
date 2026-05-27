import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class IVaultLifecycleService {
  /// Создание нового хранилища
  AsyncResultDart<Session, AppError> createStore({
    required CreateStoreDto dto,
    required String masterPassword,
  });

  /// Открытие существующего хранилища
  AsyncResultDart<Session, AppError> openStore({
    required OpenStoreDto dto,
    required String masterPassword,
    bool allowMigration = false,
  });

  /// Закрытие текущего хранилища
  AsyncResultDart<Unit, AppError> closeStore();

  /// Обновление метаданных хранилища
  AsyncResultDart<StoreInfoDto, AppError> updateStore(PatchStoreDto dto);

  /// Получение информации о текущем хранилище
  AsyncResultDart<StoreInfoDto, AppError> getStoreInfo();

  /// Удаление хранилища (из истории и опционально с диска)
  AsyncResultDart<Unit, AppError> deleteStore(
    String path, {
    required bool deleteFromDisk,
  });
}
