import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/errors/error_enums/main_db_errors.dart';
import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:result_dart/result_dart.dart';

import '../models/dashboard_card_compat.dart';
import '../models/dashboard_filter_tab.dart';
import '../models/dashboard_query.dart';
import '../models/entity_type.dart';

typedef DashboardLoadResult = ({List<BaseCardDto> items, int totalCount});

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  VaultDashboardRepository.new,
);

abstract interface class DashboardRepository {
  Future<ResultDart<DashboardLoadResult, AppError>> load(DashboardQuery query);

  Future<ResultDart<bool, AppError>> setFavorite({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setPinned({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setArchived({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> softDelete({
    required EntityType entityType,
    required String id,
  });

  Future<ResultDart<bool, AppError>> restore({
    required EntityType entityType,
    required String id,
  });

  Future<ResultDart<bool, AppError>> permanentDelete({
    required EntityType entityType,
    required String id,
  });

  AsyncResultDart<int, AppError> bulkSetFavorite({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetPinned({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetArchived({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSoftDelete({
    required EntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkPermanentDelete({
    required EntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkAssignCategory({
    required EntityType entityType,
    required List<String> ids,
    required String? categoryId,
  });

  AsyncResultDart<bool, AppError> bulkAssignTags({
    required EntityType entityType,
    required List<String> ids,
    required List<String> tagIds,
  });
}

final class VaultDashboardRepository implements DashboardRepository {
  const VaultDashboardRepository(this._ref);

  final Ref _ref;

  @override
  Future<ResultDart<DashboardLoadResult, AppError>> load(
    DashboardQuery query,
  ) {
    return _guard(() async {
      final service = await _ref.read(vaultCardFilterServiceProvider.future);
      final base = _buildBaseFilter(query);
      final items = await _loadItems(service, query, base);
      final totalCount = await _countItems(service, query, base);

      return (items: items, totalCount: totalCount);
    });
  }

  @override
  Future<ResultDart<bool, AppError>> setFavorite({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _guardBool(() => _runStateOperation(
      entityType,
      (service) => switch (entityType) {
        EntityType.password => service.password.setFavorite(id, value),
        EntityType.note => service.note.setFavorite(id, value),
        EntityType.otp => service.otp.setFavorite(id, value),
        EntityType.bankCard => service.bankCard.setFavorite(id, value),
        EntityType.file => service.file.setFavorite(id, value),
        EntityType.document => service.document.setFavorite(id, value),
        EntityType.contact => service.contact.setFavorite(id, value),
        EntityType.apiKey => service.apiKey.setFavorite(id, value),
        EntityType.sshKey => service.sshKey.setFavorite(id, value),
        EntityType.certificate => service.certificate.setFavorite(id, value),
        EntityType.cryptoWallet => service.cryptoWallet.setFavorite(id, value),
        EntityType.wifi => service.wifi.setFavorite(id, value),
        EntityType.identity => service.identity.setFavorite(id, value),
        EntityType.licenseKey => service.licenseKey.setFavorite(id, value),
        EntityType.recoveryCodes => service.recoveryCodes.setFavorite(
          id,
          value,
        ),
        EntityType.loyaltyCard => service.loyaltyCard.setFavorite(id, value),
      },
    ));
  }

  @override
  Future<ResultDart<bool, AppError>> setPinned({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _guardBool(() => _runStateOperation(
      entityType,
      (service) => switch (entityType) {
        EntityType.password => service.password.setPinned(id, value),
        EntityType.note => service.note.setPinned(id, value),
        EntityType.otp => service.otp.setPinned(id, value),
        EntityType.bankCard => service.bankCard.setPinned(id, value),
        EntityType.file => service.file.setPinned(id, value),
        EntityType.document => service.document.setPinned(id, value),
        EntityType.contact => service.contact.setPinned(id, value),
        EntityType.apiKey => service.apiKey.setPinned(id, value),
        EntityType.sshKey => service.sshKey.setPinned(id, value),
        EntityType.certificate => service.certificate.setPinned(id, value),
        EntityType.cryptoWallet => service.cryptoWallet.setPinned(id, value),
        EntityType.wifi => service.wifi.setPinned(id, value),
        EntityType.identity => service.identity.setPinned(id, value),
        EntityType.licenseKey => service.licenseKey.setPinned(id, value),
        EntityType.recoveryCodes => service.recoveryCodes.setPinned(id, value),
        EntityType.loyaltyCard => service.loyaltyCard.setPinned(id, value),
      },
    ));
  }

  @override
  Future<ResultDart<bool, AppError>> setArchived({
    required EntityType entityType,
    required String id,
    required bool value,
  }) {
    return _guardBool(() => _runStateOperation(
      entityType,
      (service) => value
          ? switch (entityType) {
              EntityType.password => service.password.archive(id),
              EntityType.note => service.note.archive(id),
              EntityType.otp => service.otp.archive(id),
              EntityType.bankCard => service.bankCard.archive(id),
              EntityType.file => service.file.archive(id),
              EntityType.document => service.document.archive(id),
              EntityType.contact => service.contact.archive(id),
              EntityType.apiKey => service.apiKey.archive(id),
              EntityType.sshKey => service.sshKey.archive(id),
              EntityType.certificate => service.certificate.archive(id),
              EntityType.cryptoWallet => service.cryptoWallet.archive(id),
              EntityType.wifi => service.wifi.archive(id),
              EntityType.identity => service.identity.archive(id),
              EntityType.licenseKey => service.licenseKey.archive(id),
              EntityType.recoveryCodes => service.recoveryCodes.archive(id),
              EntityType.loyaltyCard => service.loyaltyCard.archive(id),
            }
          : switch (entityType) {
              EntityType.password => service.password.restoreArchived(id),
              EntityType.note => service.note.restoreArchived(id),
              EntityType.otp => service.otp.restoreArchived(id),
              EntityType.bankCard => service.bankCard.restoreArchived(id),
              EntityType.file => service.file.restoreArchived(id),
              EntityType.document => service.document.restoreArchived(id),
              EntityType.contact => service.contact.restoreArchived(id),
              EntityType.apiKey => service.apiKey.restoreArchived(id),
              EntityType.sshKey => service.sshKey.restoreArchived(id),
              EntityType.certificate => service.certificate.restoreArchived(
                id,
              ),
              EntityType.cryptoWallet => service.cryptoWallet.restoreArchived(
                id,
              ),
              EntityType.wifi => service.wifi.restoreArchived(id),
              EntityType.identity => service.identity.restoreArchived(id),
              EntityType.licenseKey => service.licenseKey.restoreArchived(id),
              EntityType.recoveryCodes => service.recoveryCodes
                  .restoreArchived(id),
              EntityType.loyaltyCard => service.loyaltyCard.restoreArchived(
                id,
              ),
            },
    ));
  }

  @override
  Future<ResultDart<bool, AppError>> softDelete({
    required EntityType entityType,
    required String id,
  }) {
    return _guardBool(() => _runStateOperation(
      entityType,
      (service) => switch (entityType) {
        EntityType.password => service.password.softDelete(id),
        EntityType.note => service.note.softDelete(id),
        EntityType.otp => service.otp.softDelete(id),
        EntityType.bankCard => service.bankCard.softDelete(id),
        EntityType.file => service.file.softDelete(id),
        EntityType.document => service.document.softDelete(id),
        EntityType.contact => service.contact.softDelete(id),
        EntityType.apiKey => service.apiKey.softDelete(id),
        EntityType.sshKey => service.sshKey.softDelete(id),
        EntityType.certificate => service.certificate.softDelete(id),
        EntityType.cryptoWallet => service.cryptoWallet.softDelete(id),
        EntityType.wifi => service.wifi.softDelete(id),
        EntityType.identity => service.identity.softDelete(id),
        EntityType.licenseKey => service.licenseKey.softDelete(id),
        EntityType.recoveryCodes => service.recoveryCodes.softDelete(id),
        EntityType.loyaltyCard => service.loyaltyCard.softDelete(id),
      },
    ));
  }

  @override
  Future<ResultDart<bool, AppError>> restore({
    required EntityType entityType,
    required String id,
  }) {
    return _guardBool(() => _runStateOperation(
      entityType,
      (service) => switch (entityType) {
        EntityType.password => service.password.recover(id),
        EntityType.note => service.note.recover(id),
        EntityType.otp => service.otp.recover(id),
        EntityType.bankCard => service.bankCard.recover(id),
        EntityType.file => service.file.recover(id),
        EntityType.document => service.document.recover(id),
        EntityType.contact => service.contact.recover(id),
        EntityType.apiKey => service.apiKey.recover(id),
        EntityType.sshKey => service.sshKey.recover(id),
        EntityType.certificate => service.certificate.recover(id),
        EntityType.cryptoWallet => service.cryptoWallet.recover(id),
        EntityType.wifi => service.wifi.recover(id),
        EntityType.identity => service.identity.recover(id),
        EntityType.licenseKey => service.licenseKey.recover(id),
        EntityType.recoveryCodes => service.recoveryCodes.recover(id),
        EntityType.loyaltyCard => service.loyaltyCard.recover(id),
      },
    ));
  }

  @override
  Future<ResultDart<bool, AppError>> permanentDelete({
    required EntityType entityType,
    required String id,
  }) {
    return _guardBool(() => _deletePermanently(entityType, id));
  }

  @override
  AsyncResultDart<int, AppError> bulkSetFavorite({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _guard(
      () => _runBulk(ids, (id) => setFavorite(
        entityType: entityType,
        id: id,
        value: value,
      )),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSetPinned({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _guard(
      () => _runBulk(ids, (id) => setPinned(
        entityType: entityType,
        id: id,
        value: value,
      )),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSetArchived({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  }) {
    return _guard(
      () => _runBulk(ids, (id) => setArchived(
        entityType: entityType,
        id: id,
        value: value,
      )),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkSoftDelete({
    required EntityType entityType,
    required List<String> ids,
  }) {
    return _guard(
      () => _runBulk(
        ids,
        (id) => softDelete(entityType: entityType, id: id),
      ),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkPermanentDelete({
    required EntityType entityType,
    required List<String> ids,
  }) {
    return _guard(
      () => _runBulk(
        ids,
        (id) => permanentDelete(entityType: entityType, id: id),
      ),
    );
  }

  @override
  AsyncResultDart<int, AppError> bulkAssignCategory({
    required EntityType entityType,
    required List<String> ids,
    required String? categoryId,
  }) {
    return _guard(() async {
      final relations = await _ref.read(
        vaultItemRelationsServiceProvider.future,
      );
      var changed = 0;
      for (final id in ids) {
        (await relations.changeCategory(
          itemId: id,
          categoryId: categoryId,
        ))
            .getOrThrow();
        changed++;
      }
      return changed;
    });
  }

  @override
  AsyncResultDart<bool, AppError> bulkAssignTags({
    required EntityType entityType,
    required List<String> ids,
    required List<String> tagIds,
  }) {
    return _guardBool(() async {
      final relations = await _ref.read(
        vaultItemRelationsServiceProvider.future,
      );
      for (final id in ids) {
        (await relations.replaceTags(itemId: id, tagIds: tagIds)).getOrThrow();
      }
    });
  }

  Future<List<BaseCardDto>> _loadItems(
    VaultCardFilterService service,
    DashboardQuery query,
    BaseFilter base,
  ) async {
    return switch (query.entityType) {
      EntityType.password => (await service.getPasswords(
        _passwordFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.note => (await service.getNotes(
        _noteFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.otp => (await service.getOtps(
        _otpFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.bankCard => (await service.getBankCards(
        _bankCardFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.file => (await service.getFiles(
        _fileFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.document => (await service.getDocuments(
        _documentFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.contact => (await service.getContacts(
        _contactFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.apiKey => (await service.getApiKeys(
        _apiKeyFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.sshKey => (await service.getSshKeys(
        _sshKeyFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.certificate => (await service.getCertificates(
        _certificateFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.cryptoWallet => (await service.getCryptoWallets(
        _cryptoWalletFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.wifi => (await service.getWifis(
        _wifiFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.identity => (await service.getIdentities(
        _identityFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.licenseKey => (await service.getLicenseKeys(
        _licenseKeyFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.recoveryCodes => (await service.getRecoveryCodes(
        _recoveryCodesFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
      EntityType.loyaltyCard => (await service.getLoyaltyCards(
        _loyaltyCardFilter(query.entityFilter, base),
      ))
          .getOrThrow()
          .map((item) => wrapCard(item))
          .toList(),
    };
  }

  Future<int> _countItems(
    VaultCardFilterService service,
    DashboardQuery query,
    BaseFilter base,
  ) async {
    final countBase = base.copyWith(limit: null, offset: 0);
    return switch (query.entityType) {
      EntityType.password => (await service.countPasswords(
        _passwordFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.note => (await service.countNotes(
        _noteFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.otp => (await service.countOtps(
        _otpFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.bankCard => (await service.countBankCards(
        _bankCardFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.file => (await service.countFiles(
        _fileFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.document => (await service.countDocuments(
        _documentFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.contact => (await service.countContacts(
        _contactFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.apiKey => (await service.countApiKeys(
        _apiKeyFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.sshKey => (await service.countSshKeys(
        _sshKeyFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.certificate => (await service.countCertificates(
        _certificateFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.cryptoWallet => (await service.countCryptoWallets(
        _cryptoWalletFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.wifi => (await service.countWifis(
        _wifiFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.identity => (await service.countIdentities(
        _identityFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.licenseKey => (await service.countLicenseKeys(
        _licenseKeyFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.recoveryCodes => (await service.countRecoveryCodes(
        _recoveryCodesFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
      EntityType.loyaltyCard => (await service.countLoyaltyCards(
        _loyaltyCardFilter(query.entityFilter, countBase),
      ))
          .getOrThrow(),
    };
  }

  BaseFilter _buildBaseFilter(DashboardQuery query) {
    final source = _extractBaseFilter(query.entityFilter);
    final pageSize = query.filters.pageSize;
    final page = query.page < 0 ? 0 : query.page;
    final withPaging = source.copyWith(
      query: query.filters.query.trim(),
      limit: pageSize,
      offset: page * pageSize,
    );

    return switch (query.filters.tab) {
      DashboardFilterTab.active => withPaging.copyWith(
        isArchived: false,
        isDeleted: false,
        isFavorite: null,
        isFrequentlyUsed: null,
      ),
      DashboardFilterTab.favorites => withPaging.copyWith(
        isArchived: false,
        isDeleted: false,
        isFavorite: true,
        isFrequentlyUsed: null,
      ),
      DashboardFilterTab.frequentlyUsed => withPaging.copyWith(
        isArchived: false,
        isDeleted: false,
        isFavorite: null,
        isFrequentlyUsed: true,
      ),
      DashboardFilterTab.archived => withPaging.copyWith(
        isArchived: true,
        isDeleted: false,
        isFavorite: null,
        isFrequentlyUsed: null,
      ),
      DashboardFilterTab.deleted => withPaging.copyWith(
        isArchived: null,
        isDeleted: true,
        isFavorite: null,
        isFrequentlyUsed: null,
      ),
    };
  }

  BaseFilter _extractBaseFilter(Object filter) {
    return switch (filter) {
      PasswordFilter(:final base) => base,
      NoteFilter(:final base) => base,
      OtpFilter(:final base) => base,
      BankCardFilter(:final base) => base,
      FileFilter(:final base) => base,
      DocumentFilter(:final base) => base,
      ContactFilter(:final base) => base,
      ApiKeyFilter(:final base) => base,
      SshKeyFilter(:final base) => base,
      CertificateFilter(:final base) => base,
      CryptoWalletFilter(:final base) => base,
      WifiFilter(:final base) => base,
      IdentityFilter(:final base) => base,
      LicenseKeyFilter(:final base) => base,
      RecoveryCodesFilter(:final base) => base,
      LoyaltyCardFilter(:final base) => base,
      _ => const BaseFilter(),
    };
  }

  PasswordFilter _passwordFilter(Object filter, BaseFilter base) =>
      filter is PasswordFilter ? filter.copyWith(base: base) : PasswordFilter(base: base);

  NoteFilter _noteFilter(Object filter, BaseFilter base) =>
      filter is NoteFilter ? filter.copyWith(base: base) : NoteFilter(base: base);

  OtpFilter _otpFilter(Object filter, BaseFilter base) =>
      filter is OtpFilter ? filter.copyWith(base: base) : OtpFilter(base: base);

  BankCardFilter _bankCardFilter(Object filter, BaseFilter base) =>
      filter is BankCardFilter ? filter.copyWith(base: base) : BankCardFilter(base: base);

  FileFilter _fileFilter(Object filter, BaseFilter base) =>
      filter is FileFilter ? filter.copyWith(base: base) : FileFilter(base: base);

  DocumentFilter _documentFilter(Object filter, BaseFilter base) =>
      filter is DocumentFilter ? filter.copyWith(base: base) : DocumentFilter(base: base);

  ContactFilter _contactFilter(Object filter, BaseFilter base) =>
      filter is ContactFilter ? filter.copyWith(base: base) : ContactFilter(base: base);

  ApiKeyFilter _apiKeyFilter(Object filter, BaseFilter base) =>
      filter is ApiKeyFilter ? filter.copyWith(base: base) : ApiKeyFilter(base: base);

  SshKeyFilter _sshKeyFilter(Object filter, BaseFilter base) =>
      filter is SshKeyFilter ? filter.copyWith(base: base) : SshKeyFilter(base: base);

  CertificateFilter _certificateFilter(Object filter, BaseFilter base) =>
      filter is CertificateFilter
      ? filter.copyWith(base: base)
      : CertificateFilter(base: base);

  CryptoWalletFilter _cryptoWalletFilter(Object filter, BaseFilter base) =>
      filter is CryptoWalletFilter
      ? filter.copyWith(base: base)
      : CryptoWalletFilter(base: base);

  WifiFilter _wifiFilter(Object filter, BaseFilter base) =>
      filter is WifiFilter ? filter.copyWith(base: base) : WifiFilter(base: base);

  IdentityFilter _identityFilter(Object filter, BaseFilter base) =>
      filter is IdentityFilter ? filter.copyWith(base: base) : IdentityFilter(base: base);

  LicenseKeyFilter _licenseKeyFilter(Object filter, BaseFilter base) =>
      filter is LicenseKeyFilter
      ? filter.copyWith(base: base)
      : LicenseKeyFilter(base: base);

  RecoveryCodesFilter _recoveryCodesFilter(Object filter, BaseFilter base) =>
      filter is RecoveryCodesFilter
      ? filter.copyWith(base: base)
      : RecoveryCodesFilter(base: base);

  LoyaltyCardFilter _loyaltyCardFilter(Object filter, BaseFilter base) =>
      filter is LoyaltyCardFilter
      ? filter.copyWith(base: base)
      : LoyaltyCardFilter(base: base);

  Future<void> _runStateOperation(
    EntityType entityType,
    Future<DBResult<Unit>> Function(VaultEntityServices services) operation,
  ) async {
    final services = await _ref.read(vaultEntityServices.future);
    (await operation(services)).getOrThrow();
  }

  Future<void> _deletePermanently(EntityType entityType, String id) async {
    final repositories = await _ref.read(vaultRepositories.future);
    final result = switch (entityType) {
      EntityType.password => repositories.password.deletePermanently(id),
      EntityType.note => repositories.note.deletePermanently(id),
      EntityType.otp => repositories.otp.deletePermanently(id),
      EntityType.bankCard => repositories.bankCard.deletePermanently(id),
      EntityType.file => repositories.file.deletePermanently(id),
      EntityType.document => repositories.document.deletePermanently(id),
      EntityType.contact => repositories.contact.deletePermanently(id),
      EntityType.apiKey => repositories.apiKey.deletePermanently(id),
      EntityType.sshKey => repositories.sshKey.deletePermanently(id),
      EntityType.certificate => repositories.certificate.deletePermanently(id),
      EntityType.cryptoWallet => repositories.cryptoWallet.deletePermanently(
        id,
      ),
      EntityType.wifi => repositories.wifi.deletePermanently(id),
      EntityType.identity => repositories.identity.deletePermanently(id),
      EntityType.licenseKey => repositories.licenseKey.deletePermanently(id),
      EntityType.recoveryCodes => repositories.recoveryCodes.deletePermanently(
        id,
      ),
      EntityType.loyaltyCard => repositories.loyaltyCard.deletePermanently(id),
    };
    (await result).getOrThrow();
  }

  Future<int> _runBulk(
    List<String> ids,
    Future<ResultDart<bool, AppError>> Function(String id) operation,
  ) async {
    var changed = 0;
    for (final id in ids) {
      final result = await operation(id);
      result.getOrThrow();
      changed++;
    }
    return changed;
  }

  Future<ResultDart<bool, AppError>> _guardBool(
    Future<void> Function() operation,
  ) {
    return _guard(() async {
      await operation();
      return true;
    });
  }

  Future<ResultDart<T, AppError>> _guard<T extends Object>(
    Future<T> Function() operation,
  ) async {
    try {
      return Success(await operation());
    } catch (error, stackTrace) {
      return Failure(_mapError(error, stackTrace));
    }
  }

  AppError _mapError(Object error, StackTrace stackTrace) {
    if (error is AppError) return error;
    if (error is DBCoreError) {
      return AppError.mainDatabase(
        code: _dbErrorCode(error),
        message: _dbErrorMessage(error),
        debugMessage: error.toString(),
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      );
    }

    return AppError.mainDatabase(
      code: MainDatabaseErrorCode.unknown,
      message: 'Ошибка при выполнении операции dashboard',
      debugMessage: error.toString(),
      cause: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }

  MainDatabaseErrorCode _dbErrorCode(DBCoreError error) {
    return switch (error) {
      DbNotFoundError() => MainDatabaseErrorCode.recordNotFound,
      DbValidationError() => MainDatabaseErrorCode.validationError,
      DbConstraintError() => MainDatabaseErrorCode.validationError,
      DbConflictError() => MainDatabaseErrorCode.updateFailed,
      DbSqliteError() => MainDatabaseErrorCode.queryFailed,
      DbUnknownError() => MainDatabaseErrorCode.unknown,
    };
  }

  String _dbErrorMessage(DBCoreError error) {
    return switch (error) {
      DbNotFoundError(:final entity, :final id, :final message) =>
        message ?? 'Запись не найдена: $entity/$id',
      DbValidationError(:final message) => message,
      DbConstraintError(:final message) => message,
      DbConflictError(:final message) => message,
      DbSqliteError(:final message) => message,
      DbUnknownError(:final message) => message,
    };
  }
}
