import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

class DateTimeConverter extends TypeConverter<DateTime, String> {
  @override
  DateTime fromSql(String fromDb) {
    try {
      return DateTime.parse(fromDb);
    } catch (e) {
      // Логируем ошибку и возвращаем fallback (например, текущую дату)
      logError(
        'Failed to parse DateTime from database',
        error: e,
        tag: 'DateTimeConverter',
      );
      return DateTime.now();
    }
  }

  @override
  String toSql(DateTime value) => value.toIso8601String();
}
