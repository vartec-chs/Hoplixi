import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/dao/bank_card_dao.dart';
import 'package:hoplixi/main_store/dao/category_dao.dart';
import 'package:hoplixi/main_store/dao/file_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/bank_card_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/file_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/note_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/otp_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/password_history_dao.dart';
import 'package:hoplixi/main_store/dao/icon_dao.dart';
import 'package:hoplixi/main_store/dao/note_dao.dart';
import 'package:hoplixi/main_store/dao/note_link_dao.dart';
import 'package:hoplixi/main_store/dao/otp_dao.dart';
import 'package:hoplixi/main_store/dao/password_dao.dart';
import 'package:hoplixi/main_store/dao/store_meta_dao.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/index.dart';
import 'package:hoplixi/main_store/triggers/index.dart';
import 'package:uuid/uuid.dart';

import './dao/filters_dao/filters_dao.dart';

part 'main_store.g.dart';

@DriftDatabase(
  tables: [
    StoreMetaTable,
    Passwords,
    PasswordsHistory,
    Otps,
    OtpsHistory,
    Notes,
    NotesHistory,
    NoteLinks,
    BankCards,
    BankCardsHistory,
    Files,
    FileMetadata,
    FilesTags,
    FilesHistory,
    Categories,
    Tags,
    Icons,
    PasswordsTags,
    OtpsTags,
    NotesTags,
    BankCardsTags,
    Documents,
    DocumentPages,
    DocumentsTags,
  ],
  daos: [
    StoreMetaDao,
    PasswordDao,
    PasswordHistoryDao,
    OtpDao,
    OtpHistoryDao,
    NoteDao,
    NoteHistoryDao,
    NoteLinkDao,
    BankCardDao,
    BankCardHistoryDao,
    FileDao,
    FileHistoryDao,
    CategoryDao,
    IconDao,
    BankCardFilterDao,
    FileFilterDao,
    NoteFilterDao,
    OtpFilterDao,
    PasswordFilterDao,
  ],
)
class MainStore extends _$MainStore {
  static const String _logTag = 'MainStore';

  MainStore(super.e);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Установка триггеров для записи истории изменений
        await _installHistoryTriggers();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        // Переустановка триггеров при каждом открытии БД
        // (на случай если они были удалены или изменены)
        // await _installHistoryTriggers();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo(
          'Migrating database from version $from to $to',
          tag: '${_logTag}Migration',
        );

        // // Миграция до версии 5: добавление таблицы связей между заметками
        // if (from < 5) {
        //   await m.createTable(noteLinks);
        //   logInfo('Created note_links table', tag: '${_logTag}Migration');
        // }

        logInfo('Migration completed', tag: '${_logTag}Migration');
      },
    );
  }

  @override
  int get schemaVersion => MainConstants.databaseSchemaVersion;

  /// Поток для отслеживания изменений в данных
  ///
  /// Эмитирует событие каждый раз при изменении данных в любой таблице
  Stream<void> watchDataChanged() {
    return customSelect(
      'SELECT 1', // данные нам не нужны
      readsFrom: {
        passwords,
        passwordsHistory,
        otps,
        otpsHistory,
        notes,
        notesHistory,
        noteLinks,
        bankCards,
        bankCardsHistory,
        files,
        filesHistory,
        categories,
        tags,
        icons,
        passwordsTags,
        otpsTags,
        notesTags,
        bankCardsTags,
        filesTags,
        documents,
        documentPages,
        documentsTags,
      }, // отслеживаем все основные таблицы
    ).watch().map((_) {
      return;
    }); // превращаем в Stream<void>
  }

  /// Установка триггеров для автоматической записи истории изменений
  /// и управления временными метками
  Future<void> _installHistoryTriggers() async {
    logInfo('Installing triggers...', tag: _logTag);

    try {
      // Удаляем старые триггеры истории (если есть)
      for (final drop in [
        ...passwordsHistoryDropTriggers,
        ...otpsHistoryDropTriggers,
        ...notesHistoryDropTriggers,
        ...filesHistoryDropTriggers,
        ...bankCardsHistoryDropTriggers,
        ...documentsDropTriggers,
      ]) {
        await customStatement(drop);
      }

      // Удаляем старые триггеры временных меток (если есть)
      for (final drop in allTimestampDropTriggers) {
        await customStatement(drop);
      }

      // Удаляем старые триггеры обновления store_meta (если есть)
      for (final drop in allMetaTouchDropTriggers) {
        await customStatement(drop);
      }

      // Создаём триггеры истории изменений
      for (final trigger in [
        ...passwordsHistoryCreateTriggers,
        ...otpsHistoryCreateTriggers,
        ...notesHistoryCreateTriggers,
        ...filesHistoryCreateTriggers,
        ...bankCardsHistoryCreateTriggers,
        ...documentsDeleteTriggers,
      ]) {
        await customStatement(trigger);
      }

      // Создаём триггеры для автоматической установки created_at
      for (final trigger in allInsertTimestampTriggers) {
        await customStatement(trigger);
      }

      // Создаём триггеры для автоматического обновления modified_at
      for (final trigger in allModifiedAtTriggers) {
        await customStatement(trigger);
      }

      // Создаём триггеры для обновления store_meta при изменениях в таблицах
      for (final trigger in allMetaTouchCreateTriggers) {
        await customStatement(trigger);
      }

      logInfo('All triggers installed successfully', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to install triggers',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }
}
