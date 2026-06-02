import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/usecases/utils/error_handling.dart';
import 'package:result_dart/result_dart.dart';

class CloseVaultDB {
  static const String _logTag = 'CloseVaultDB';

  AsyncResultDart<Unit, AppError> call({required Session session}) async {
    try {
      logInfo(
        'Closing store',
        tag: _logTag,
        data: {'path': session.storeDirectoryPath},
      );

      await session.api.db.close();

      logInfo('Store closed successfully', tag: _logTag);
      return const Success(unit);
    } catch (error, stackTrace) {
      return handleVaultDBUseCaseError(
        message: 'Failed to close store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }
}
