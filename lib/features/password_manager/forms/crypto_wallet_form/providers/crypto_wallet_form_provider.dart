import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';
import 'package:hoplixi/main_db/core/tables/crypto_wallet/crypto_wallet_items.dart';

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

    final repository = await ref.read(cryptoWalletRepositoryProvider.future);
    final view = await repository.getViewById(id);
    if (view == null) return const CryptoWalletFormState(isEditMode: false);

    final item = view.item;
    final wallet = view.cryptoWallet;

    // TODO: handle tags properly
    final customFields = await loadCustomFields(ref, id);

    return CryptoWalletFormState(
      isEditMode: true,
      editingCryptoWalletId: id,
      name: item.name,
      walletType: wallet.walletType?.name ?? '',
      mnemonic: wallet.mnemonic ?? '',
      privateKey: wallet.privateKey ?? '',
      derivationPath: wallet.derivationPath ?? '',
      network: wallet.network?.name ?? '',
      addresses: wallet.addresses ?? '',
      xpub: wallet.xpub ?? '',
      xprv: wallet.xprv ?? '',
      hardwareDevice: wallet.hardwareDevice ?? '',
      derivationScheme: wallet.derivationScheme?.name ?? '',
      description: item.description ?? '',
      watchOnly: wallet.watchOnly,
      categoryId: item.categoryId,
      tagIds: [],
      customFields: customFields,
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
      nameError: v.trim().isEmpty
          ? t.dashboard_forms.validation_required_name
          : null,
    ),
  );
  void setWalletType(String v) => _update(
    (s) => s.copyWith(
      walletType: v,
      walletTypeError: v.trim().isEmpty
          ? t.dashboard_forms.validation_required_wallet_type
          : null,
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
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setWatchOnly(bool v) => _update((s) => s.copyWith(watchOnly: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty
        ? t.dashboard_forms.validation_required_name
        : null;
    final walletTypeError = c.walletType.trim().isEmpty
        ? t.dashboard_forms.validation_required_wallet_type
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
      final repository = await ref.read(cryptoWalletRepositoryProvider.future);

      if (c.isEditMode && c.editingCryptoWalletId != null) {
        await repository.update(
          PatchCryptoWalletDto(
            item: VaultItemPatchDto(
              itemId: c.editingCryptoWalletId!,
              name: FieldUpdate.set(c.name.trim()),
              description: FieldUpdate.set(clean(c.description)),
              categoryId: FieldUpdate.set(c.categoryId),
            ),
            cryptoWallet: PatchCryptoWalletDataDto(
              walletType: FieldUpdate.set(
                c.walletType.isEmpty ? null : CryptoWalletType.values.byName(c.walletType),
              ),
              mnemonic: FieldUpdate.set(clean(c.mnemonic)),
              privateKey: FieldUpdate.set(clean(c.privateKey)),
              derivationPath: FieldUpdate.set(clean(c.derivationPath)),
              network: FieldUpdate.set(
                c.network.isEmpty ? null : CryptoNetwork.values.byName(c.network),
              ),
              addresses: FieldUpdate.set(clean(c.addresses)),
              xpub: FieldUpdate.set(clean(c.xpub)),
              xprv: FieldUpdate.set(clean(c.xprv)),
              hardwareDevice: FieldUpdate.set(clean(c.hardwareDevice)),
              derivationScheme: FieldUpdate.set(
                c.derivationScheme.isEmpty
                    ? null
                    : CryptoDerivationScheme.values.byName(c.derivationScheme),
              ),
              watchOnly: FieldUpdate.set(c.watchOnly),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        await saveCustomFields(ref, c.editingCryptoWalletId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.cryptoWallet,
              entityId: c.editingCryptoWalletId,
            );
      } else {
        final id = await repository.create(
          CreateCryptoWalletDto(
            item: VaultItemCreateDto(
              name: c.name.trim(),
              description: clean(c.description),
              categoryId: c.categoryId,
            ),
            cryptoWallet: CryptoWalletDataDto(
              walletType: c.walletType.isEmpty
                  ? null
                  : CryptoWalletType.values.byName(c.walletType),
              mnemonic: clean(c.mnemonic),
              privateKey: clean(c.privateKey),
              derivationPath: clean(c.derivationPath),
              network: c.network.isEmpty
                  ? null
                  : CryptoNetwork.values.byName(c.network),
              addresses: clean(c.addresses),
              xpub: clean(c.xpub),
              xprv: clean(c.xprv),
              hardwareDevice: clean(c.hardwareDevice),
              derivationScheme: c.derivationScheme.isEmpty
                  ? null
                  : CryptoDerivationScheme.values.byName(c.derivationScheme),
              watchOnly: c.watchOnly,
            ),
          ),
        );

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.cryptoWallet, entityId: id);
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
