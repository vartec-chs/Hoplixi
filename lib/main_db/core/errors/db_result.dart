import 'package:result_dart/result_dart.dart';

import 'db_error.dart';

typedef DbResult<T extends Object> = ResultDart<T, DBCoreError>;
typedef AsyncDbResult<T extends Object> = AsyncResultDart<T, DBCoreError>;
