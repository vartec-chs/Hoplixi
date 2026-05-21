import 'package:result_dart/result_dart.dart';
export 'package:hoplixi/core/utils/result/optional.dart';
export 'package:hoplixi/core/utils/result/result_utils.dart';

import 'db_error.dart';

typedef DbResult<T extends Object> = ResultDart<T, DBCoreError>;
typedef AsyncDbResult<T extends Object> = AsyncResultDart<T, DBCoreError>;
