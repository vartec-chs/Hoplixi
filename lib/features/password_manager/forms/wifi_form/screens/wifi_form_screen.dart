import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/login_autocomplete_field/login_autocomplete_field.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/old/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:op_wifi_utils/op_wifi_utils.dart';

import '../models/wifi_form_state.dart';
import '../providers/wifi_form_provider.dart';
import '../services/wifi_os_bridge.dart';

class WifiFormScreen extends ConsumerStatefulWidget {
  const WifiFormScreen({super.key, this.wifiId});

  final String? wifiId;

  @override
  ConsumerState<WifiFormScreen> createState() => _WifiFormScreenState();
}

class _WifiFormScreenState extends ConsumerState<WifiFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;
  late final TextEditingController _securityController;
  late final TextEditingController _eapMethodController;
  late final TextEditingController _usernameController;
  late final TextEditingController _identityController;
  late final TextEditingController _domainController;
  late final TextEditingController _bssidController;
  late final TextEditingController _priorityController;
  late final TextEditingController _qrPayloadController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
    _securityController = TextEditingController();
    _eapMethodController = TextEditingController();
    _usernameController = TextEditingController();
    _identityController = TextEditingController();
    _domainController = TextEditingController();
    _bssidController = TextEditingController();
    _priorityController = TextEditingController();
    _qrPayloadController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _securityController.dispose();
    _eapMethodController.dispose();
    _usernameController.dispose();
    _identityController.dispose();
    _domainController.dispose();
    _bssidController.dispose();
    _priorityController.dispose();
    _qrPayloadController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(wifiFormProvider(widget.wifiId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.check_form_fields_and_try_again,
      );
    }
  }

  Future<void> _fillCurrentSsid() async {
    final l10n = context.t.dashboard_forms;

    if (!WifiOsBridge.supportsWifiConnection) {
      Toaster.info(
        title: l10n.network_label,
        description: WifiOsBridge.describeError(
          OpWifiUtilsError.unsupportedPlatform,
        ),
      );
      return;
    }

    final result = await WifiOsBridge.getCurrentSsid();
    if (!mounted) return;

    result.fold(
      (ssid) {
        ref
            .read(wifiFormProvider(widget.wifiId).notifier)
            .applyImportedSsid(ssid);

        Toaster.success(title: l10n.wifi_ssid_label, description: ssid);
      },
      (error) {
        Toaster.error(
          title: l10n.common_load_error,
          description: WifiOsBridge.describeError(error),
        );
      },
    );
  }

  Future<void> _exportToWifi(WifiFormState state) async {
    final l10n = context.t.dashboard_forms;
    final ssid = state.ssid.trim();

    if (ssid.isEmpty) {
      Toaster.warning(title: l10n.validation_required_ssid);
      return;
    }

    final result = await WifiOsBridge.connect(
      ssid: ssid,
      password: state.password,
    );
    if (!mounted) return;

    result.fold(
      (_) {
        Toaster.success(title: l10n.network_label, description: ssid);
      },
      (error) {
        Toaster.error(
          title: l10n.network_label,
          description: WifiOsBridge.describeError(error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(wifiFormProvider(widget.wifiId));

    ref.listen(wifiFormProvider(widget.wifiId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.wifiId != null
              ? context.t.dashboard_forms.wifi_updated
              : context.t.dashboard_forms.wifi_created,
        );
        ref.read(wifiFormProvider(widget.wifiId).notifier).resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    return stateAsync.when(
      loading: () => Scaffold(
        backgroundColor: getScreenBackgroundColor(context, ref),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: getScreenBackgroundColor(context, ref),
        appBar: AppBar(
          leading: const FormCloseButton(),
          title: Text(context.t.dashboard_forms.form_error),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_ssidController.text != state.ssid) {
          _ssidController.text = state.ssid;
        }
        if (_passwordController.text != state.password) {
          _passwordController.text = state.password;
        }
        if (_securityController.text != state.security) {
          _securityController.text = state.security;
        }
        if (_eapMethodController.text != state.eapMethod) {
          _eapMethodController.text = state.eapMethod;
        }
        if (_usernameController.text != state.username) {
          _usernameController.text = state.username;
        }
        if (_identityController.text != state.identity) {
          _identityController.text = state.identity;
        }
        if (_domainController.text != state.domain) {
          _domainController.text = state.domain;
        }
        if (_bssidController.text != state.lastConnectedBssid) {
          _bssidController.text = state.lastConnectedBssid;
        }
        if (_priorityController.text != state.priority) {
          _priorityController.text = state.priority;
        }
        if (_qrPayloadController.text != state.qrCodePayload) {
          _qrPayloadController.text = state.qrCodePayload;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(wifiFormProvider(widget.wifiId).notifier);

        return Scaffold(
          backgroundColor: getScreenBackgroundColor(context, ref),
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_wifi
                  : context.t.dashboard_forms.new_wifi_network,
            ),
            actions: [
              IconButton(
                tooltip: context.t.dashboard_forms.network_label,
                onPressed: state.isSaving ? null : () => _exportToWifi(state),
                icon: const Icon(Icons.upload_rounded),
              ),
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(icon: const Icon(Icons.save), onPressed: _save),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: formPadding,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.name_label,
                    errorText: state.nameError,
                    prefixIcon: const Icon(LucideIcons.tag),
                  ),
                  onChanged: notifier.setName,
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _ssidController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.wifi_ssid_label,
                    errorText: state.ssidError,
                    prefixIcon: const Icon(LucideIcons.wifi),
                    helperText: context.t.dashboard_forms.wifi_ssid_description,
                    suffixIcon: IconButton(
                      tooltip: context.t.dashboard_forms.wifi_ssid_auto_get,
                      icon: const Icon(Icons.download_rounded),
                      onPressed: _fillCurrentSsid,
                    ),
                  ),
                  onChanged: notifier.setSsid,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.wifi_password_label,
                    prefixIcon: const Icon(LucideIcons.lock),
                  ),
                  onChanged: notifier.setPassword,
                ),
                const SizedBox(height: 12),
                IconSourcePickerButton(
                  iconRef: IconRefDto.fromFields(
                    iconSource: state.iconSource,
                    iconValue: state.iconValue,
                  ),
                  fallbackIcon: Icons.wifi,
                  title: 'Иконка записи',
                  onChanged: notifier.setIconRef,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [CategoryType.wifi, CategoryType.mixed],
                  onCategorySelected: notifier.setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.wifi, TagType.mixed],
                  onTagsSelected: notifier.setTags,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.description_label,
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: notifier.setDescription,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: Text(context.t.dashboard_forms.advanced_settings),
                  children: [
                    TextField(
                      controller: _eapMethodController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText:
                            context.t.dashboard_forms.wifi_eap_method_label,
                        prefixIcon: const Icon(LucideIcons.settings),
                      ),
                      onChanged: notifier.setEapMethod,
                    ),
                    const SizedBox(height: 12),
                    LoginAutocompleteField(
                      controller: _usernameController,
                      labelText: context.t.dashboard_forms.wifi_username_label,
                      prefixIcon: const Icon(LucideIcons.user),
                      onChanged: notifier.setUsername,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _identityController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText:
                            context.t.dashboard_forms.wifi_identity_label,
                        prefixIcon: const Icon(LucideIcons.idCard),
                      ),
                      onChanged: notifier.setIdentity,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _domainController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: context.t.dashboard_forms.wifi_domain_label,
                        prefixIcon: const Icon(LucideIcons.globe),
                      ),
                      onChanged: notifier.setDomain,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bssidController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: context
                            .t
                            .dashboard_forms
                            .wifi_last_connected_bssid_label,
                        prefixIcon: const Icon(LucideIcons.monitor),
                      ),
                      onChanged: notifier.setLastConnectedBssid,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priorityController,
                      keyboardType: TextInputType.number,
                      decoration: primaryInputDecoration(
                        context,
                        labelText:
                            context.t.dashboard_forms.wifi_priority_label,
                        errorText: state.priorityError,
                        prefixIcon: const Icon(LucideIcons.arrowUpDown),
                      ),
                      onChanged: notifier.setPriority,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qrPayloadController,
                      maxLines: 2,
                      decoration: primaryInputDecoration(
                        context,
                        labelText:
                            context.t.dashboard_forms.wifi_qr_payload_label,
                        prefixIcon: const Icon(LucideIcons.qrCode),
                      ),
                      onChanged: notifier.setQrCodePayload,
                    ),
                    const SizedBox(height: 12),
                    NotePickerField(
                      selectedNoteId: state.noteId,
                      selectedNoteName: state.noteName,
                      onNoteSelected: notifier.setNote,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: state.hidden,
                      onChanged: notifier.setHidden,
                      title: Text(
                        context.t.dashboard_forms.wifi_hidden_network_label,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomFieldsEditor(
                      fields: state.customFields,
                      onChanged: notifier.setCustomFields,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
