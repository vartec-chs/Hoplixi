import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';
import '../../../core/daos/daos.dart';
import '../../../core/main_store.dart';
import '../../../core/models/dto/dto.dart';
import '../../../core/models/mappers/history/vault_snapshot_history_mapper.dart';
import '../../models/filters/history/vault_snapshot_history_filter.dart';
import '../../tables/vault_items/vault_items.dart';

class VaultHistoryReadService {
  VaultHistoryReadService({
    required this.snapshotFilterDao,
    required this.snapshotsHistoryDao,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.bankCardHistoryDao,
    required this.certificateHistoryDao,
    required this.cryptoWalletHistoryDao,
    required this.wifiHistoryDao,
    required this.sshKeyHistoryDao,
    required this.licenseKeyHistoryDao,
    required this.otpHistoryDao,
    required this.recoveryCodesHistoryDao,
    required this.loyaltyCardHistoryDao,
    required this.fileHistoryDao,
    required this.contactHistoryDao,
    required this.identityHistoryDao,
    required this.noteHistoryDao,
  });

  final VaultSnapshotHistoryFilterDao snapshotFilterDao;
  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final BankCardHistoryDao bankCardHistoryDao;
  final CertificateHistoryDao certificateHistoryDao;
  final CryptoWalletHistoryDao cryptoWalletHistoryDao;
  final WifiHistoryDao wifiHistoryDao;
  final SshKeyHistoryDao sshKeyHistoryDao;
  final LicenseKeyHistoryDao licenseKeyHistoryDao;
  final OtpHistoryDao otpHistoryDao;
  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;
  final FileMetadataHistoryDao fileHistoryDao;
  final ContactHistoryDao contactHistoryDao;
  final IdentityHistoryDao identityHistoryDao;
  final NoteHistoryDao noteHistoryDao;

  Future<DbResult<List<VaultHistoryCardDto>>> getFilteredCards(
    VaultSnapshotHistoryFilter filter,
  ) async {
    try {
      final snapshots = await snapshotFilterDao.getFiltered(filter);
      if (snapshots.isEmpty) return Success(const []);
      final cards = await _assembleCards(snapshots);
      return Success(cards);
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }

  Future<DbResult<VaultHistoryCardDto>> getCardByHistoryId(String historyId) async {
    try {
      final snapshot = await snapshotsHistoryDao.getSnapshotById(historyId);
      if (snapshot == null) {
        return Failure(DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId));
      }
      final cards = await _assembleCards([snapshot]);
      if (cards.isEmpty) {
        return Failure(DBCoreError.notFound(entity: 'HistorySnapshotData', id: historyId));
      }
      return Success(cards.first);
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
  Future<List<VaultHistoryCardDto>> _assembleCards(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    final Map<VaultItemType, List<String>> historyIdsByType = {};
    for (final s in snapshots) {
      historyIdsByType.putIfAbsent(s.type, () => []).add(s.id);
    }

    final Map<String, dynamic> dataMap = {};

    if (historyIdsByType.containsKey(VaultItemType.apiKey)) {
      final ids = historyIdsByType[VaultItemType.apiKey]!;
      final map = await apiKeyHistoryDao.getApiKeyHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.password)) {
      final ids = historyIdsByType[VaultItemType.password]!;
      final map = await passwordHistoryDao.getPasswordHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.bankCard)) {
      final ids = historyIdsByType[VaultItemType.bankCard]!;
      final map = await bankCardHistoryDao.getBankCardHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.certificate)) {
      final ids = historyIdsByType[VaultItemType.certificate]!;
      final map = await certificateHistoryDao.getCertificateHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.cryptoWallet)) {
      final ids = historyIdsByType[VaultItemType.cryptoWallet]!;
      final map = await cryptoWalletHistoryDao.getCryptoWalletHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.wifi)) {
      final ids = historyIdsByType[VaultItemType.wifi]!;
      final map = await wifiHistoryDao.getWifiHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.sshKey)) {
      final ids = historyIdsByType[VaultItemType.sshKey]!;
      final map = await sshKeyHistoryDao.getSshKeyHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.licenseKey)) {
      final ids = historyIdsByType[VaultItemType.licenseKey]!;
      final map = await licenseKeyHistoryDao.getLicenseKeyHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.otp)) {
      final ids = historyIdsByType[VaultItemType.otp]!;
      final map = await otpHistoryDao.getOtpHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.recoveryCodes)) {
      final ids = historyIdsByType[VaultItemType.recoveryCodes]!;
      final map = await recoveryCodesHistoryDao.getRecoveryCodesHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.loyaltyCard)) {
      final ids = historyIdsByType[VaultItemType.loyaltyCard]!;
      final map = await loyaltyCardHistoryDao.getLoyaltyCardHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.file)) {
      final ids = historyIdsByType[VaultItemType.file]!;
      final map = await fileHistoryDao.getFileHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.contact)) {
      final ids = historyIdsByType[VaultItemType.contact]!;
      final map = await contactHistoryDao.getContactHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.identity)) {
      final ids = historyIdsByType[VaultItemType.identity]!;
      final map = await identityHistoryDao.getIdentityHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }
    if (historyIdsByType.containsKey(VaultItemType.note)) {
      final ids = historyIdsByType[VaultItemType.note]!;
      final map = await noteHistoryDao.getNoteHistoryCardDataByHistoryIds(ids);
      dataMap.addAll(map);
    }

    final List<VaultHistoryCardDto> result = [];

    for (final snapshot in snapshots) {
      final snapshotDto = snapshot.toVaultSnapshotCardDto();
      final historyId = snapshot.id;

      switch (snapshot.type) {
        case VaultItemType.apiKey:
          final data = dataMap[historyId] as ApiKeyHistoryCardDataDto?;
          if (data != null) {
            result.add(ApiKeyHistoryCardDto(snapshot: snapshotDto, apikey: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.password:
          final data = dataMap[historyId] as PasswordHistoryCardDataDto?;
          if (data != null) {
            result.add(PasswordHistoryCardDto(snapshot: snapshotDto, password: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.bankCard:
          final data = dataMap[historyId] as BankCardHistoryCardDataDto?;
          if (data != null) {
            result.add(BankCardHistoryCardDto(snapshot: snapshotDto, bankcard: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.certificate:
          final data = dataMap[historyId] as CertificateHistoryCardDataDto?;
          if (data != null) {
            result.add(CertificateHistoryCardDto(snapshot: snapshotDto, certificate: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.cryptoWallet:
          final data = dataMap[historyId] as CryptoWalletHistoryCardDataDto?;
          if (data != null) {
            result.add(CryptoWalletHistoryCardDto(snapshot: snapshotDto, cryptowallet: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.wifi:
          final data = dataMap[historyId] as WifiHistoryCardDataDto?;
          if (data != null) {
            result.add(WifiHistoryCardDto(snapshot: snapshotDto, wifi: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.sshKey:
          final data = dataMap[historyId] as SshKeyHistoryCardDataDto?;
          if (data != null) {
            result.add(SshKeyHistoryCardDto(snapshot: snapshotDto, sshkey: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.licenseKey:
          final data = dataMap[historyId] as LicenseKeyHistoryCardDataDto?;
          if (data != null) {
            result.add(LicenseKeyHistoryCardDto(snapshot: snapshotDto, licensekey: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.otp:
          final data = dataMap[historyId] as OtpHistoryCardDataDto?;
          if (data != null) {
            result.add(OtpHistoryCardDto(snapshot: snapshotDto, otp: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.recoveryCodes:
          final data = dataMap[historyId] as RecoveryCodesHistoryCardDataDto?;
          if (data != null) {
            result.add(RecoveryCodesHistoryCardDto(snapshot: snapshotDto, recoverycodes: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.loyaltyCard:
          final data = dataMap[historyId] as LoyaltyCardHistoryCardDataDto?;
          if (data != null) {
            result.add(LoyaltyCardHistoryCardDto(snapshot: snapshotDto, loyaltycard: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.file:
          final data = dataMap[historyId] as FileHistoryCardDataDto?;
          if (data != null) {
            result.add(FileHistoryCardDto(snapshot: snapshotDto, file: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.contact:
          final data = dataMap[historyId] as ContactHistoryCardDataDto?;
          if (data != null) {
            result.add(ContactHistoryCardDto(snapshot: snapshotDto, contact: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.identity:
          final data = dataMap[historyId] as IdentityHistoryCardDataDto?;
          if (data != null) {
            result.add(IdentityHistoryCardDto(snapshot: snapshotDto, identity: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.note:
          final data = dataMap[historyId] as NoteHistoryCardDataDto?;
          if (data != null) {
            result.add(NoteHistoryCardDto(snapshot: snapshotDto, note: data));
          } else {
            result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          }
          break;
        case VaultItemType.document:
          result.add(DocumentHistoryCardDto(snapshot: snapshotDto));
          break;
        default:
          result.add(GenericHistoryCardDto(snapshot: snapshotDto));
          break;
      }
    }

    return result;
  }
}
