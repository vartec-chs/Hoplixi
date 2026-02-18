import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/dao/note_link_dao.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:riverpod/riverpod.dart';

import '../dao/index.dart';
import 'main_store_provider.dart';

typedef _DaoFactory<TDao> = TDao Function(MainStore store);

Future<TDao> _ensureDao<TDao>(Ref ref, _DaoFactory<TDao> factory) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }
  return factory(store);
}

final passwordDaoProvider = FutureProvider<PasswordDao>(
  (ref) => _ensureDao(ref, (store) => PasswordDao(store)),
);

final passwordHistoryDaoProvider = FutureProvider<PasswordHistoryDao>(
  (ref) => _ensureDao(ref, (store) => PasswordHistoryDao(store)),
);

final otpDaoProvider = FutureProvider<OtpDao>(
  (ref) => _ensureDao(ref, (store) => OtpDao(store)),
);

final otpHistoryDaoProvider = FutureProvider<OtpHistoryDao>(
  (ref) => _ensureDao(ref, (store) => OtpHistoryDao(store)),
);

final noteDaoProvider = FutureProvider<NoteDao>(
  (ref) => _ensureDao(ref, (store) => NoteDao(store)),
);

final noteHistoryDaoProvider = FutureProvider<NoteHistoryDao>(
  (ref) => _ensureDao(ref, (store) => NoteHistoryDao(store)),
);

final bankCardDaoProvider = FutureProvider<BankCardDao>(
  (ref) => _ensureDao(ref, (store) => BankCardDao(store)),
);

final bankCardHistoryDaoProvider = FutureProvider<BankCardHistoryDao>(
  (ref) => _ensureDao(ref, (store) => BankCardHistoryDao(store)),
);

final fileDaoProvider = FutureProvider<FileDao>(
  (ref) => _ensureDao(ref, (store) => FileDao(store)),
);

final fileHistoryDaoProvider = FutureProvider<FileHistoryDao>(
  (ref) => _ensureDao(ref, (store) => FileHistoryDao(store)),
);

final categoryDaoProvider = FutureProvider<CategoryDao>(
  (ref) => _ensureDao(ref, (store) => CategoryDao(store)),
);

final iconDaoProvider = FutureProvider<IconDao>(
  (ref) => _ensureDao(ref, (store) => IconDao(store)),
);

final tagDaoProvider = FutureProvider<TagDao>(
  (ref) => _ensureDao(ref, (store) => TagDao(store)),
);

final passwordFilterDaoProvider = FutureProvider<PasswordFilterDao>(
  (ref) => _ensureDao(ref, (store) => PasswordFilterDao(store)),
);

final otpFilterDaoProvider = FutureProvider<OtpFilterDao>(
  (ref) => _ensureDao(ref, (store) => OtpFilterDao(store)),
);

final noteFilterDaoProvider = FutureProvider<NoteFilterDao>(
  (ref) => _ensureDao(ref, (store) => NoteFilterDao(store)),
);

final bankCardFilterDaoProvider = FutureProvider<BankCardFilterDao>(
  (ref) => _ensureDao(ref, (store) => BankCardFilterDao(store)),
);

final fileFilterDaoProvider = FutureProvider<FileFilterDao>(
  (ref) => _ensureDao(ref, (store) => FileFilterDao(store)),
);

final noteLinkDaoProvider = FutureProvider<NoteLinkDao>(
  (ref) => _ensureDao(ref, (store) => NoteLinkDao(store)),
);

final storeMetaDaoProvider = FutureProvider<StoreMetaDao>(
  (ref) => _ensureDao(ref, (store) => StoreMetaDao(store)),
);

final documentDaoProvider = FutureProvider<DocumentDao>(
  (ref) => _ensureDao(ref, (store) => DocumentDao(store)),
);

final documentFilterDaoProvider = FutureProvider<DocumentFilterDao>(
  (ref) => _ensureDao(ref, (store) => DocumentFilterDao(store)),
);

final vaultItemDaoProvider = FutureProvider<VaultItemDao>(
  (ref) => _ensureDao(ref, (store) => VaultItemDao(store)),
);
