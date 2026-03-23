import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_form_data.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/widgets/app_credential_setup_info_card.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/widgets/cloud_sync_provider_selector.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Экран создания и редактирования пользовательских app credentials.
class AppCredentialEditorScreen extends ConsumerStatefulWidget {
  const AppCredentialEditorScreen({super.key, this.initialEntry});

  final AppCredentialEntry? initialEntry;

  @override
  ConsumerState<AppCredentialEditorScreen> createState() =>
      _AppCredentialEditorScreenState();
}

class _AppCredentialEditorScreenState
    extends ConsumerState<AppCredentialEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late AppCredentialFormData _formData;
  late AppCredentialPlatformTarget _platformTarget;
  bool _isSaving = false;
  bool _obscureClientSecret = true;

  bool get _isEdit => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _formData = AppCredentialFormData(
      provider: entry?.provider ?? AppCredentialFormData().provider,
      name: entry?.name ?? '',
      clientId: entry?.clientId ?? '',
      clientSecret: entry?.clientSecret ?? '',
    );
    _platformTarget = entry?.platformTarget ?? AppCredentialPlatformTarget.all;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_app_credentials;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.edit_screen_title : l10n.create_screen_title,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.provider_label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                CloudSyncProviderSelector(
                  value: _formData.provider,
                  onChanged: (provider) {
                    setState(() {
                      _formData = _formData.copyWith(provider: provider);
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Platform Target',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AppCredentialPlatformTarget>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<AppCredentialPlatformTarget>(
                      value: AppCredentialPlatformTarget.all,
                      label: Text('All'),
                      icon: Icon(Icons.devices_outlined),
                    ),
                    ButtonSegment<AppCredentialPlatformTarget>(
                      value: AppCredentialPlatformTarget.desktop,
                      label: Text('Desktop'),
                      icon: Icon(Icons.desktop_windows_outlined),
                    ),
                    ButtonSegment<AppCredentialPlatformTarget>(
                      value: AppCredentialPlatformTarget.mobile,
                      label: Text('Mobile'),
                      icon: Icon(Icons.smartphone_outlined),
                    ),
                  ],
                  selected: <AppCredentialPlatformTarget>{_platformTarget},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _platformTarget = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this to restrict the credential to desktop, mobile, or both.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                AppCredentialSetupInfoCard(provider: _formData.provider),
                const SizedBox(height: 20),
                PrimaryTextFormField(
                  label: l10n.name_field_label,
                  hintText: l10n.name_field_hint,
                  initialValue: _formData.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    _formData = _formData.copyWith(name: value);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.name_required_error;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryTextFormField(
                  label: l10n.client_id_field_label,
                  hintText: l10n.client_id_field_hint,
                  initialValue: _formData.clientId,
                  onChanged: (value) {
                    _formData = _formData.copyWith(clientId: value);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.client_id_required_error;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _formData.clientSecret,
                  obscureText: _obscureClientSecret,
                  onChanged: (value) {
                    _formData = _formData.copyWith(clientSecret: value);
                  },
                  decoration: primaryInputDecoration(
                    context,
                    labelText: l10n.client_secret_field_label,
                    hintText: l10n.client_secret_field_hint,
                    helperText: l10n.client_secret_helper,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureClientSecret = !_obscureClientSecret;
                        });
                      },
                      icon: Icon(
                        _obscureClientSecret
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SmoothButton(
                        label: l10n.cancel_button,
                        type: SmoothButtonType.outlined,
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SmoothButton(
                        label: l10n.save_button,
                        loading: _isSaving,
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final l10n = context.t.cloud_sync_app_credentials;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final initial = widget.initialEntry;
    final entry = AppCredentialEntry(
      id: initial?.id ?? _uuid.v4(),
      provider: _formData.provider,
      name: _formData.trimmedName,
      clientId: _formData.trimmedClientId,
      clientSecret: _formData.normalizedClientSecret,
      isBuiltin: false,
      platformTarget: _platformTarget,
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
    );

    try {
      await ref.read(appCredentialsProvider.notifier).saveUserEntry(entry);
      if (!mounted) {
        return;
      }

      Toaster.success(
        title: _isEdit ? l10n.update_success_title : l10n.create_success_title,
        description: _isEdit
            ? l10n.update_success_description
            : l10n.create_success_description,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      Toaster.error(
        title: l10n.save_error_title,
        description: l10n.save_error_description,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
