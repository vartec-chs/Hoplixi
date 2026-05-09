import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/errors/error_enums/main_db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/result_extensions.dart';
import 'package:hoplixi/main_db/core/daos/crud/vault_item_dao.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/filter/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:result_dart/result_dart.dart';

import '../models/dashboard_entity_type.dart';
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
  Future<ResultDart<DashboardLoadResult, AppError>> load(DashboardQuery query) {
    return ResultUtils.tryCatchAsync(
      () async {
        final baseFilter = _buildBaseFilter(query);
        final items = await _loadItems(query.entityType, baseFilter);
        final totalCount = await _countItems(query.entityType, baseFilter);
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
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.toggleFavorite(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> setPinned({
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.togglePin(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> setArchived({
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  }) {
    return _mutate(entityType, id, (dao) => dao.toggleArchive(id, value));
  }

  @override
  Future<ResultDart<bool, AppError>> softDelete({
    required DashboardEntityType entityType,
    required String id,
  }) {
    return _mutate(entityType, id, (dao) => dao.softDelete(id));
  }

  @override
  Future<ResultDart<bool, AppError>> restore({
    required DashboardEntityType entityType,
    required String id,
  }) {
    return _mutate(entityType, id, (dao) => dao.restoreFromDeleted(id));
  }

  @override
  Future<ResultDart<bool, AppError>> permanentDelete({
    required DashboardEntityType entityType,
    required String id,
  }) {
    return _mutate(entityType, id, (dao) => dao.permanentDelete(id));
  }

  BaseFilter _buildBaseFilter(DashboardQuery query) {
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
      DashboardFilterTab.pinned => (
        isArchived: false,
        isDeleted: false,
        isFavorite: null,
        isPinned: true,
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

    return BaseFilter.create(
      query: query.filters.query,
      isArchived: tabFilter.isArchived,
      isDeleted: tabFilter.isDeleted,
      isFavorite: tabFilter.isFavorite,
      isPinned: tabFilter.isPinned,
      limit: query.filters.pageSize,
      offset: query.page * query.filters.pageSize,
      sortBy: SortBy.modifiedAt,
      sortDirection: SortDirection.desc,
    );
  }

  Future<List<BaseCardDto>> _loadItems(
    DashboardEntityType entityType,
    BaseFilter base,
  ) async {
    return switch (entityType) {
      DashboardEntityType.password => await (await _ref.read(
        passwordFilterDaoProvider.future,
      )).getFiltered(PasswordsFilter.create(base: base)),
      DashboardEntityType.note => await (await _ref.read(
        noteFilterDaoProvider.future,
      )).getFiltered(NotesFilter.create(base: base)),
      DashboardEntityType.bankCard => await (await _ref.read(
        bankCardFilterDaoProvider.future,
      )).getFiltered(BankCardsFilter.create(base: base)),
      DashboardEntityType.file => await (await _ref.read(
        fileFilterDaoProvider.future,
      )).getFiltered(FilesFilter.create(base: base)),
      DashboardEntityType.otp => await (await _ref.read(
        otpFilterDaoProvider.future,
      )).getFiltered(OtpsFilter.create(base: base)),
      DashboardEntityType.document => await (await _ref.read(
        documentFilterDaoProvider.future,
      )).getFiltered(DocumentsFilter.create(base: base)),
      DashboardEntityType.contact => await (await _ref.read(
        contactFilterDaoProvider.future,
      )).getFiltered(ContactsFilter.create(base: base)),
      DashboardEntityType.apiKey => await (await _ref.read(
        apiKeyFilterDaoProvider.future,
      )).getFiltered(ApiKeysFilter.create(base: base)),
      DashboardEntityType.sshKey => await (await _ref.read(
        sshKeyFilterDaoProvider.future,
      )).getFiltered(SshKeysFilter.create(base: base)),
      DashboardEntityType.certificate => await (await _ref.read(
        certificateFilterDaoProvider.future,
      )).getFiltered(CertificatesFilter.create(base: base)),
      DashboardEntityType.cryptoWallet => await (await _ref.read(
        cryptoWalletFilterDaoProvider.future,
      )).getFiltered(CryptoWalletsFilter.create(base: base)),
      DashboardEntityType.wifi => await (await _ref.read(
        wifiFilterDaoProvider.future,
      )).getFiltered(WifisFilter.create(base: base)),
      DashboardEntityType.identity => await (await _ref.read(
        identityFilterDaoProvider.future,
      )).getFiltered(IdentitiesFilter.create(base: base)),
      DashboardEntityType.licenseKey => await (await _ref.read(
        licenseKeyFilterDaoProvider.future,
      )).getFiltered(LicenseKeysFilter.create(base: base)),
      DashboardEntityType.recoveryCodes => await (await _ref.read(
        recoveryCodesFilterDaoProvider.future,
      )).getFiltered(RecoveryCodesFilter.create(base: base)),
      DashboardEntityType.loyaltyCard => await (await _ref.read(
        loyaltyCardFilterDaoProvider.future,
      )).getFiltered(LoyaltyCardsFilter.create(base: base)),
    };
  }

  Future<int> _countItems(
    DashboardEntityType entityType,
    BaseFilter base,
  ) async {
    return switch (entityType) {
      DashboardEntityType.password => await (await _ref.read(
        passwordFilterDaoProvider.future,
      )).countFiltered(PasswordsFilter.create(base: base)),
      DashboardEntityType.note => await (await _ref.read(
        noteFilterDaoProvider.future,
      )).countFiltered(NotesFilter.create(base: base)),
      DashboardEntityType.bankCard => await (await _ref.read(
        bankCardFilterDaoProvider.future,
      )).countFiltered(BankCardsFilter.create(base: base)),
      DashboardEntityType.file => await (await _ref.read(
        fileFilterDaoProvider.future,
      )).countFiltered(FilesFilter.create(base: base)),
      DashboardEntityType.otp => await (await _ref.read(
        otpFilterDaoProvider.future,
      )).countFiltered(OtpsFilter.create(base: base)),
      DashboardEntityType.document => await (await _ref.read(
        documentFilterDaoProvider.future,
      )).countFiltered(DocumentsFilter.create(base: base)),
      DashboardEntityType.contact => await (await _ref.read(
        contactFilterDaoProvider.future,
      )).countFiltered(ContactsFilter.create(base: base)),
      DashboardEntityType.apiKey => await (await _ref.read(
        apiKeyFilterDaoProvider.future,
      )).countFiltered(ApiKeysFilter.create(base: base)),
      DashboardEntityType.sshKey => await (await _ref.read(
        sshKeyFilterDaoProvider.future,
      )).countFiltered(SshKeysFilter.create(base: base)),
      DashboardEntityType.certificate => await (await _ref.read(
        certificateFilterDaoProvider.future,
      )).countFiltered(CertificatesFilter.create(base: base)),
      DashboardEntityType.cryptoWallet => await (await _ref.read(
        cryptoWalletFilterDaoProvider.future,
      )).countFiltered(CryptoWalletsFilter.create(base: base)),
      DashboardEntityType.wifi => await (await _ref.read(
        wifiFilterDaoProvider.future,
      )).countFiltered(WifisFilter.create(base: base)),
      DashboardEntityType.identity => await (await _ref.read(
        identityFilterDaoProvider.future,
      )).countFiltered(IdentitiesFilter.create(base: base)),
      DashboardEntityType.licenseKey => await (await _ref.read(
        licenseKeyFilterDaoProvider.future,
      )).countFiltered(LicenseKeysFilter.create(base: base)),
      DashboardEntityType.recoveryCodes => await (await _ref.read(
        recoveryCodesFilterDaoProvider.future,
      )).countFiltered(RecoveryCodesFilter.create(base: base)),
      DashboardEntityType.loyaltyCard => await (await _ref.read(
        loyaltyCardFilterDaoProvider.future,
      )).countFiltered(LoyaltyCardsFilter.create(base: base)),
    };
  }

  Future<ResultDart<bool, AppError>> _mutate(
    DashboardEntityType entityType,
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
