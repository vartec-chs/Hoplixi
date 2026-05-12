import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/errors/error_enums/main_db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/result_extensions.dart';
import 'package:hoplixi/main_db/core/old/daos/crud/vault_item_dao.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:hoplixi/main_db/core/old/models/filter/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/main_db/providers/other/service_providers.dart';
import 'package:result_dart/result_dart.dart';

import '../models/entity_type.dart';
import '../models/dashboard_filter_tab.dart';
import '../models/dashboard_query.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  MainDbDashboardRepository.new,
);

final class MainDbDashboardRepository implements DashboardRepository {
  MainDbDashboardRepository(this._ref);

  static const _logTag = 'DashboardV2Repository';

  final Ref _ref;

  @override
  AsyncResultDart<DashboardLoadResult, AppError> load(DashboardQuery query) {
    return ResultUtils.tryCatchAsync(
      () async {
        final baseFilter = _buildBaseFilter(query);
        final items = await _loadItems(
          query.entityType,
          query.entityFilter,
          baseFilter,
        );
        final totalCount = await _countItems(
          query.entityType,
          query.entityFilter,
          baseFilter,
        );
        return (items: items, totalCount: totalCount);
      },
      (error, stackTrace) => _mapError(
        'Не удалось загрузить элементы dashboard',
        error,
        stackTrace,
        {'entityType': query.entityType.id},
      ),
    );
  }

  @override
  Future<ResultDart<bool, AppError>> setFavorite({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.toggleFavorite(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> setPinned({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.togglePin(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> setArchived({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.toggleArchive(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> softDelete({
    required EntityType entityType,
    required String id,
  }) {
    return _mutate(entityType, id, (dao) => dao.softDelete(id));
  }

  @override
  Future<ResultDart<bool, AppError>> restore({
    required EntityType entityType,
    required String id,
  }) {
    return _mutate(entityType, id, (dao) => dao.restoreFromDeleted(id));
  }

  @override
  Future<ResultDart<bool, AppError>> permanentDelete({
    required EntityType entityType,
    required String id,
  }) {
    return ResultUtils.tryCatchAsync(
      () async => _permanentDeleteItem(entityType, id),
      (error, stackTrace) => _mapError(
        'Не удалось окончательно удалить элемент dashboard',
        error,
        stackTrace,
        {'entityType': entityType.id, 'id': id},
      ),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSetFavorite({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _bulkMutate(
      entityType: entityType,
      ids: ids,
      action: (dao) => dao.bulkSetFavorite(ids, value),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSetPinned({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _bulkMutate(
      entityType: entityType,
      ids: ids,
      action: (dao) => dao.bulkSetPin(ids, value),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSetArchived({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _bulkMutate(
      entityType: entityType,
      ids: ids,
      action: (dao) => dao.bulkSetArchive(ids, value),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSoftDelete({
    required EntityType entityType,
    required List<String> ids,
  }) {
    return _bulkMutate(
      entityType: entityType,
      ids: ids,
      action: (dao) => dao.bulkSoftDelete(ids),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkPermanentDelete({
    required EntityType entityType,
    required List<String> ids,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        var deletedCount = 0;
        for (final id in ids) {
          if (await _permanentDeleteItem(entityType, id)) deletedCount++;
        }
        return deletedCount;
      },
      (error, stackTrace) => _mapError(
        'Не удалось окончательно удалить элементы dashboard',
        error,
        stackTrace,
        {'entityType': entityType.id, 'ids': ids},
      ),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkAssignCategory({
    required EntityType entityType,
    required List<String> ids,
    required String? categoryId,
  }) {
    return _bulkMutate(
      entityType: entityType,
      ids: ids,
      action: (dao) => dao.bulkSetCategory(ids, categoryId),
    );
  }

  @override
  AsyncResultDart<bool, AppError> bulkAssignTags({
    required EntityType entityType,
    required List<String> ids,
    required List<String> tagIds,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final dao = await _ref.read(vaultItemDaoProvider.future);
        await dao.bulkSyncTags(ids, tagIds);
        return true;
      },
      (error, stackTrace) => _mapError(
        'Не удалось назначить теги элементам dashboard',
        error,
        stackTrace,
        {'entityType': entityType.id, 'ids': ids},
      ),
    );
  }

  BaseFilter _buildBaseFilter(DashboardQuery query) {
    final sourceBase = _entityBaseFilter(query.entityFilter);
    final tabFilter = switch (query.filters.tab) {
      DashboardFilterTab.active => (
        isArchived: false,
        isDeleted: false,
        isFavorite: null,
        isPinned: null,
      ),
      DashboardFilterTab.favorites => (
        isArchived: false,
        isDeleted: false,
        isFavorite: true,
        isPinned: null,
      ),
      DashboardFilterTab.frequentlyUsed => (
        isArchived: false,
        isDeleted: false,
        isFavorite: null,
        isPinned: null,
      ),
      DashboardFilterTab.archived => (
        isArchived: true,
        isDeleted: false,
        isFavorite: null,
        isPinned: null,
      ),
      DashboardFilterTab.deleted => (
        isArchived: null,
        isDeleted: true,
        isFavorite: null,
        isPinned: null,
      ),
    };
    final tabOverridesStatus = query.filters.tab != DashboardFilterTab.active;

    return sourceBase.copyWith(
      query: query.filters.query.isNotEmpty
          ? query.filters.query
          : sourceBase.query,
      isArchived: tabOverridesStatus
          ? tabFilter.isArchived
          : sourceBase.isArchived ?? tabFilter.isArchived,
      isDeleted: tabOverridesStatus
          ? tabFilter.isDeleted
          : sourceBase.isDeleted ?? tabFilter.isDeleted,
      isFavorite: tabOverridesStatus
          ? tabFilter.isFavorite
          : sourceBase.isFavorite ?? tabFilter.isFavorite,
      isPinned: tabOverridesStatus
          ? tabFilter.isPinned
          : sourceBase.isPinned ?? tabFilter.isPinned,
      limit: query.filters.pageSize,
      offset: query.page * query.filters.pageSize,
    );
  }

  Future<List<BaseCardDto>> _loadItems(
    EntityType entityType,
    Object entityFilter,
    BaseFilter base,
  ) async {
    return switch (entityType) {
      EntityType.password => await (await _ref.read(
        passwordFilterDaoProvider.future,
      )).getFiltered(_passwordsFilter(entityFilter, base)),
      EntityType.note => await (await _ref.read(
        noteFilterDaoProvider.future,
      )).getFiltered(_notesFilter(entityFilter, base)),
      EntityType.bankCard => await (await _ref.read(
        bankCardFilterDaoProvider.future,
      )).getFiltered(_bankCardsFilter(entityFilter, base)),
      EntityType.file => await (await _ref.read(
        fileFilterDaoProvider.future,
      )).getFiltered(_filesFilter(entityFilter, base)),
      EntityType.otp => await (await _ref.read(
        otpFilterDaoProvider.future,
      )).getFiltered(_otpsFilter(entityFilter, base)),
      EntityType.document => await (await _ref.read(
        documentFilterDaoProvider.future,
      )).getFiltered(_documentsFilter(entityFilter, base)),
      EntityType.contact => await (await _ref.read(
        contactFilterDaoProvider.future,
      )).getFiltered(_contactsFilter(entityFilter, base)),
      EntityType.apiKey => await (await _ref.read(
        apiKeyFilterDaoProvider.future,
      )).getFiltered(_apiKeysFilter(entityFilter, base)),
      EntityType.sshKey => await (await _ref.read(
        sshKeyFilterDaoProvider.future,
      )).getFiltered(_sshKeysFilter(entityFilter, base)),
      EntityType.certificate => await (await _ref.read(
        certificateFilterDaoProvider.future,
      )).getFiltered(_certificatesFilter(entityFilter, base)),
      EntityType.cryptoWallet => await (await _ref.read(
        cryptoWalletFilterDaoProvider.future,
      )).getFiltered(_cryptoWalletsFilter(entityFilter, base)),
      EntityType.wifi => await (await _ref.read(
        wifiFilterDaoProvider.future,
      )).getFiltered(_wifisFilter(entityFilter, base)),
      EntityType.identity => await (await _ref.read(
        identityFilterDaoProvider.future,
      )).getFiltered(_identitiesFilter(entityFilter, base)),
      EntityType.licenseKey => await (await _ref.read(
        licenseKeyFilterDaoProvider.future,
      )).getFiltered(_licenseKeysFilter(entityFilter, base)),
      EntityType.recoveryCodes => await (await _ref.read(
        recoveryCodesFilterDaoProvider.future,
      )).getFiltered(_recoveryCodesFilter(entityFilter, base)),
      EntityType.loyaltyCard => await (await _ref.read(
        loyaltyCardFilterDaoProvider.future,
      )).getFiltered(_loyaltyCardsFilter(entityFilter, base)),
    };
  }

  Future<int> _countItems(
    EntityType entityType,
    Object entityFilter,
    BaseFilter base,
  ) async {
    return switch (entityType) {
      EntityType.password => await (await _ref.read(
        passwordFilterDaoProvider.future,
      )).countFiltered(_passwordsFilter(entityFilter, base)),
      EntityType.note => await (await _ref.read(
        noteFilterDaoProvider.future,
      )).countFiltered(_notesFilter(entityFilter, base)),
      EntityType.bankCard => await (await _ref.read(
        bankCardFilterDaoProvider.future,
      )).countFiltered(_bankCardsFilter(entityFilter, base)),
      EntityType.file => await (await _ref.read(
        fileFilterDaoProvider.future,
      )).countFiltered(_filesFilter(entityFilter, base)),
      EntityType.otp => await (await _ref.read(
        otpFilterDaoProvider.future,
      )).countFiltered(_otpsFilter(entityFilter, base)),
      EntityType.document => await (await _ref.read(
        documentFilterDaoProvider.future,
      )).countFiltered(_documentsFilter(entityFilter, base)),
      EntityType.contact => await (await _ref.read(
        contactFilterDaoProvider.future,
      )).countFiltered(_contactsFilter(entityFilter, base)),
      EntityType.apiKey => await (await _ref.read(
        apiKeyFilterDaoProvider.future,
      )).countFiltered(_apiKeysFilter(entityFilter, base)),
      EntityType.sshKey => await (await _ref.read(
        sshKeyFilterDaoProvider.future,
      )).countFiltered(_sshKeysFilter(entityFilter, base)),
      EntityType.certificate => await (await _ref.read(
        certificateFilterDaoProvider.future,
      )).countFiltered(_certificatesFilter(entityFilter, base)),
      EntityType.cryptoWallet => await (await _ref.read(
        cryptoWalletFilterDaoProvider.future,
      )).countFiltered(_cryptoWalletsFilter(entityFilter, base)),
      EntityType.wifi => await (await _ref.read(
        wifiFilterDaoProvider.future,
      )).countFiltered(_wifisFilter(entityFilter, base)),
      EntityType.identity => await (await _ref.read(
        identityFilterDaoProvider.future,
      )).countFiltered(_identitiesFilter(entityFilter, base)),
      EntityType.licenseKey => await (await _ref.read(
        licenseKeyFilterDaoProvider.future,
      )).countFiltered(_licenseKeysFilter(entityFilter, base)),
      EntityType.recoveryCodes => await (await _ref.read(
        recoveryCodesFilterDaoProvider.future,
      )).countFiltered(_recoveryCodesFilter(entityFilter, base)),
      EntityType.loyaltyCard => await (await _ref.read(
        loyaltyCardFilterDaoProvider.future,
      )).countFiltered(_loyaltyCardsFilter(entityFilter, base)),
    };
  }

  BaseFilter _entityBaseFilter(Object entityFilter) {
    return switch (entityFilter) {
      PasswordsFilter(:final base) => base,
      NotesFilter(:final base) => base,
      OtpsFilter(:final base) => base,
      BankCardsFilter(:final base) => base,
      FilesFilter(:final base) => base,
      DocumentsFilter(:final base) => base,
      ContactsFilter(:final base) => base,
      ApiKeysFilter(:final base) => base,
      SshKeysFilter(:final base) => base,
      CertificatesFilter(:final base) => base,
      CryptoWalletsFilter(:final base) => base,
      WifisFilter(:final base) => base,
      IdentitiesFilter(:final base) => base,
      LicenseKeysFilter(:final base) => base,
      RecoveryCodesFilter(:final base) => base,
      LoyaltyCardsFilter(:final base) => base,
      _ => const BaseFilter(),
    };
  }

  PasswordsFilter _passwordsFilter(Object filter, BaseFilter base) {
    return filter is PasswordsFilter
        ? filter.copyWith(base: base)
        : PasswordsFilter.create(base: base);
  }

  NotesFilter _notesFilter(Object filter, BaseFilter base) {
    return filter is NotesFilter
        ? filter.copyWith(base: base)
        : NotesFilter.create(base: base);
  }

  OtpsFilter _otpsFilter(Object filter, BaseFilter base) {
    return filter is OtpsFilter
        ? filter.copyWith(base: base)
        : OtpsFilter.create(base: base);
  }

  BankCardsFilter _bankCardsFilter(Object filter, BaseFilter base) {
    return filter is BankCardsFilter
        ? filter.copyWith(base: base)
        : BankCardsFilter.create(base: base);
  }

  FilesFilter _filesFilter(Object filter, BaseFilter base) {
    return filter is FilesFilter
        ? filter.copyWith(base: base)
        : FilesFilter.create(base: base);
  }

  DocumentsFilter _documentsFilter(Object filter, BaseFilter base) {
    return filter is DocumentsFilter
        ? filter.copyWith(base: base)
        : DocumentsFilter.create(base: base);
  }

  ContactsFilter _contactsFilter(Object filter, BaseFilter base) {
    return filter is ContactsFilter
        ? filter.copyWith(base: base)
        : ContactsFilter.create(base: base);
  }

  ApiKeysFilter _apiKeysFilter(Object filter, BaseFilter base) {
    return filter is ApiKeysFilter
        ? filter.copyWith(base: base)
        : ApiKeysFilter.create(base: base);
  }

  SshKeysFilter _sshKeysFilter(Object filter, BaseFilter base) {
    return filter is SshKeysFilter
        ? filter.copyWith(base: base)
        : SshKeysFilter.create(base: base);
  }

  CertificatesFilter _certificatesFilter(Object filter, BaseFilter base) {
    return filter is CertificatesFilter
        ? filter.copyWith(base: base)
        : CertificatesFilter.create(base: base);
  }

  CryptoWalletsFilter _cryptoWalletsFilter(Object filter, BaseFilter base) {
    return filter is CryptoWalletsFilter
        ? filter.copyWith(base: base)
        : CryptoWalletsFilter.create(base: base);
  }

  WifisFilter _wifisFilter(Object filter, BaseFilter base) {
    return filter is WifisFilter
        ? filter.copyWith(base: base)
        : WifisFilter.create(base: base);
  }

  IdentitiesFilter _identitiesFilter(Object filter, BaseFilter base) {
    return filter is IdentitiesFilter
        ? filter.copyWith(base: base)
        : IdentitiesFilter.create(base: base);
  }

  LicenseKeysFilter _licenseKeysFilter(Object filter, BaseFilter base) {
    return filter is LicenseKeysFilter
        ? filter.copyWith(base: base)
        : LicenseKeysFilter.create(base: base);
  }

  RecoveryCodesFilter _recoveryCodesFilter(Object filter, BaseFilter base) {
    return filter is RecoveryCodesFilter
        ? filter.copyWith(base: base)
        : RecoveryCodesFilter.create(base: base);
  }

  LoyaltyCardsFilter _loyaltyCardsFilter(Object filter, BaseFilter base) {
    return filter is LoyaltyCardsFilter
        ? filter.copyWith(base: base)
        : LoyaltyCardsFilter.create(base: base);
  }

  Future<ResultDart<bool, AppError>> _mutate(
    EntityType entityType,
    String id,
    Future<bool> Function(VaultItemDao dao) action,
  ) {
    return ResultUtils.tryCatchAsync(
      () async => action(await _ref.read(vaultItemDaoProvider.future)),
      (error, stackTrace) => _mapError(
        'Не удалось изменить элемент dashboard',
        error,
        stackTrace,
        {'entityType': entityType.id, 'id': id},
      ),
    );
  }

  AsyncResultDart<int, AppError> _bulkMutate({
    required EntityType entityType,
    required List<String> ids,
    required Future<int> Function(VaultItemDao dao) action,
  }) {
    return ResultUtils.tryCatchAsync(
      () async => action(await _ref.read(vaultItemDaoProvider.future)),
      (error, stackTrace) => _mapError(
        'Не удалось выполнить массовое действие dashboard',
        error,
        stackTrace,
        {'entityType': entityType.id, 'ids': ids},
      ),
    );
  }

  Future<bool> _permanentDeleteItem(EntityType entityType, String id) async {
    if (entityType == EntityType.file) {
      await _deleteFilePayloads(id);
    }

    final dao = await _ref.read(vaultItemDaoProvider.future);
    return dao.permanentDelete(id);
  }

  Future<void> _deleteFilePayloads(String id) async {
    final fileService = await _ref.read(fileStorageServiceProvider.future);
    final fileHistoryDao = await _ref.read(fileHistoryDaoProvider.future);
    final fileDao = await _ref.read(fileDaoProvider.future);
    final historyRecords = await fileHistoryDao.getFileHistoryByOriginalId(id);

    for (final (_, fileRecord) in historyRecords) {
      final metadataId = fileRecord?.metadataId;
      if (metadataId == null) continue;

      final metadata = await (fileDao.attachedDatabase.select(
        fileDao.attachedDatabase.fileMetadata,
      )..where((metadata) => metadata.id.equals(metadataId))).getSingleOrNull();

      final filePath = metadata?.filePath;
      if (filePath == null) continue;

      await fileService.deleteHistoryFileFromDisk(filePath);
    }

    await fileHistoryDao.deleteFileHistoryByFileId(id);
    await fileService.deleteFileFromDisk(id);
  }

  AppError _mapError(
    String message,
    Object error,
    StackTrace stackTrace,
    Map<String, dynamic> data,
  ) {
    logError(
      message,
      tag: _logTag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
    return AppError.mainDatabase(
      code: MainDatabaseErrorCode.queryFailed,
      message: message,
      debugMessage: error.toString(),
      cause: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}
