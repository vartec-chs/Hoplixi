enum DBCipher { chacha20, sqlcipher }

const Map<String, String> dbCipherDescriptions = {
  'aes128cbc': 'wxSQLite3: AES 128 Bit',
  'aes256cbc': 'wxSQLite3: AES 256 Bit',
  'chacha20': 'sqleet: ChaCha20',
  'sqlcipher': 'SQLCipher: AES 256 Bit',
  'rc4': 'System.Data.SQLite: RC4',
  'ascon128': 'Ascon: Ascon-128 v1.2',
};

const Map<String, String> dbCipherShortDescriptions = {
  'aes128cbc':
      'Старый, базовый уровень защиты. Использовать только для совместимости.',
  'aes256cbc': 'Надежный стандартный вариант, чуть тяжелее по скорости.',
  'chacha20':
      'Современный и быстрый вариант. Хорошо подходит для большинства пользователей.',
  'sqlcipher': 'Широко совместимый и проверенный вариант с сильной защитой.',
  'rc4': 'Устаревший и слабый вариант. Не рекомендуется для новых хранилищ.',
  'ascon128':
      'Современный легкий алгоритм, чаще нужен для специальных сценариев.',
};

extension DBCipherX on DBCipher {
  String get technicalDescription => dbCipherDescriptions[name] ?? name;

  String get shortDescription =>
      dbCipherShortDescriptions[name] ?? 'Описание недоступно';

  String get displayTitle => '$name ($technicalDescription)';
}
