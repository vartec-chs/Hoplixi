/// Экспорт всех SQL триггеров для записи истории изменений.
///
/// Этот файл экспортирует все триггеры для удобного импорта.
library;

// Триггеры истории изменений
export 'api_keys_triggers.dart';
export 'bank_cards_triggers.dart';
export 'certificates_triggers.dart';
export 'crypto_wallets_triggers.dart';
export 'documents_triggers.dart';
export 'files_triggers.dart';
export 'notes_triggers.dart';
export 'otps_triggers.dart';
export 'passwords_triggers.dart';
export 'ssh_keys_triggers.dart';
// Триггеры временных меток
export 'timestamps/index.dart';
export 'wifis_triggers.dart';
