import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/new/usecases/create_main_store.dart'
    show Session;
import 'package:hoplixi/main_db/new/usecases/utils/error_handling.dart';
import 'package:result_dart/result_dart.dart';

class CloseMainStore {
  static const String _logTag = 'CloseMainStore';

  AsyncResultDart<Unit, AppError> call({required Session session}) async {
    try {
      logInfo(
        'Closing store',
        tag: _logTag,
        data: {'path': session.storeDirectoryPath},
      );

      await session.store.close();

      logInfo('Store closed successfully', tag: _logTag);
      return const Success(unit);
    } catch (error, stackTrace) {
      return handleMainStoreUseCaseError(
        message: 'Failed to close store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }
}
