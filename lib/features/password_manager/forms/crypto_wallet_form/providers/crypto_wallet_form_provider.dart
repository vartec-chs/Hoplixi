import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/crypto_wallet_form_state.dart';

final cryptoWalletFormProvider = AsyncNotifierProvider.autoDispose
    .family<CryptoWalletFormNotifier, CryptoWalletFormState, String?>(
      CryptoWalletFormNotifier.new,
    );

class CryptoWalletFormNotifier extends AsyncNotifier<CryptoWalletFormState> {
  CryptoWalletFormNotifier(this.cryptoWalletId);

  final String? cryptoWalletId;

  @override
  Future<CryptoWalletFormState> build() async {
    if (cryptoWalletId == null) {
      return const CryptoWalletFormState(isEditMode: false);
    }
    final id = cryptoWalletId!;

    final dao = await ref.read(cryptoWalletDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const CryptoWalletFormState(isEditMode: false);

    final item = row.$1;
    final wallet = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return CryptoWalletFormState(
      isEditMode: true,
      editingCryptoWalletId: id,
      name: item.name,
      walletType: wallet.walletType,
      mnemonic: wallet.mnemonic ?? '',
      privateKey: wallet.privateKey ?? '',
      derivationPath: wallet.derivationPath ?? '',
      network: wallet.network ?? '',
      addresses: wallet.addresses ?? '',
      xpub: wallet.xpub ?? '',
      xprv: wallet.xprv ?? '',
      hardwareDevice: wallet.hardwareDevice ?? '',
      derivationScheme: wallet.derivationScheme ?? '',
      notesOnUsage: wallet.notesOnUsage ?? '',
      description: item.description ?? '',
      watchOnly: wallet.watchOnly,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
    );
  }

  CryptoWalletFormState get _current =>
      state.value ?? const CryptoWalletFormState();

  void _update(CryptoWalletFormState Function(CryptoWalletFormState v) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String v) => _update(
    (s) => s.copyWith(
      name: v,
      nameError: v.trim().isEmpty ? 'Название обязательно' : null,
    ),
  );
  void setWalletType(String v) => _update(
    (s) => s.copyWith(
      walletType: v,
      walletTypeError: v.trim().isEmpty ? 'Тип кошелька обязателен' : null,
    ),
  );
  void setMnemonic(String v) => _update((s) => s.copyWith(mnemonic: v));
  void setPrivateKey(String v) => _update((s) => s.copyWith(privateKey: v));
  void setDerivationPath(String v) =>
      _update((s) => s.copyWith(derivationPath: v));
  void setNetwork(String v) => _update((s) => s.copyWith(network: v));
  void setAddresses(String v) => _update((s) => s.copyWith(addresses: v));
  void setXpub(String v) => _update((s) => s.copyWith(xpub: v));
  void setXprv(String v) => _update((s) => s.copyWith(xprv: v));
  void setHardwareDevice(String v) =>
      _update((s) => s.copyWith(hardwareDevice: v));
  void setDerivationScheme(String v) =>
      _update((s) => s.copyWith(derivationScheme: v));
  void setNotesOnUsage(String v) => _update((s) => s.copyWith(notesOnUsage: v));
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setWatchOnly(bool v) => _update((s) => s.copyWith(watchOnly: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty ? 'Название обязательно' : null;
    final walletTypeError = c.walletType.trim().isEmpty
        ? 'Тип кошелька обязателен'
        : null;

    _update(
      (s) => s.copyWith(nameError: nameError, walletTypeError: walletTypeError),
    );
    return nameError == null && walletTypeError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final c = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? clean(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);

      if (c.isEditMode && c.editingCryptoWalletId != null) {
        final updated = await dao.updateCryptoWallet(
          c.editingCryptoWalletId!,
          UpdateCryptoWalletDto(
            name: c.name.trim(),
            walletType: c.walletType.trim(),
            mnemonic: clean(c.mnemonic),
            privateKey: clean(c.privateKey),
            derivationPath: clean(c.derivationPath),
            network: clean(c.network),
            addresses: clean(c.addresses),
            xpub: clean(c.xpub),
            xprv: clean(c.xprv),
            hardwareDevice: clean(c.hardwareDevice),
            derivationScheme: clean(c.derivationScheme),
            notesOnUsage: clean(c.notesOnUsage),
            description: clean(c.description),
            watchOnly: c.watchOnly,
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }
      } else {
        await dao.createCryptoWallet(
          CreateCryptoWalletDto(
            name: c.name.trim(),
            walletType: c.walletType.trim(),
            mnemonic: clean(c.mnemonic),
            privateKey: clean(c.privateKey),
            derivationPath: clean(c.derivationPath),
            network: clean(c.network),
            addresses: clean(c.addresses),
            xpub: clean(c.xpub),
            xprv: clean(c.xprv),
            hardwareDevice: clean(c.hardwareDevice),
            derivationScheme: clean(c.derivationScheme),
            notesOnUsage: clean(c.notesOnUsage),
            description: clean(c.description),
            watchOnly: c.watchOnly,
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );
      }

      _update((s) => s.copyWith(isSaving: false, isSaved: true));
      return true;
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      return false;
    }
  }

  void resetSaved() => _update((s) => s.copyWith(isSaved: false));
}
