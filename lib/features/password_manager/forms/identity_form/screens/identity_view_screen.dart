import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class IdentityViewScreen extends ConsumerStatefulWidget {
  const IdentityViewScreen({super.key, required this.identityId});

  final String identityId;

  @override
  ConsumerState<IdentityViewScreen> createState() => _IdentityViewScreenState();
}

class _IdentityViewScreenState extends ConsumerState<IdentityViewScreen> {
  bool _loading = true;
  bool _isDeleted = false;

  String _name = '';
  String? _firstName;
  String? _middleName;
  String? _lastName;
  String? _displayName;
  String? _username;
  String? _email;
  String? _phone;
  String? _address;
  DateTime? _birthday;
  String? _company;
  String? _jobTitle;
  String? _website;
  String? _taxId;
  String? _nationalId;
  String? _passportNumber;
  String? _driverLicenseNumber;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repos = await ref.read(vaultRepositories.future);
      if (!mounted) return;
      final viewResult = await repos.identity.getViewById(widget.identityId);
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(
            title: context.t.dashboard_forms.common_record_not_found,
          );
          context.pop();
        }
        return;
      }
      final item = view.item;
      final identity = view.identity;

      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _firstName = identity.firstName;
        _middleName = identity.middleName;
        _lastName = identity.lastName;
        _displayName = identity.displayName;
        _username = identity.username;
        _email = identity.email;
        _phone = identity.phone;
        _address = identity.address;
        _birthday = identity.birthday;
        _company = identity.company;
        _jobTitle = identity.jobTitle;
        _website = identity.website;
        _taxId = identity.taxId;
        _nationalId = identity.nationalId;
        _passportNumber = identity.passportNumber;
        _driverLicenseNumber = identity.driverLicenseNumber;
        _description = item.description;
      });
    } catch (e) {
      if (mounted) {
        Toaster.error(
          title: context.t.dashboard_forms.common_load_error,
          description: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? value) {
    if (value == null) return '-';
    return value.toIso8601String().split('T')[0];
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.identityId,
    );
    if (!mounted) return;
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(id: 'first_name', label: 'Имя', value: _firstName),
        shareableField(
          id: 'middle_name',
          label: 'Отчество',
          value: _middleName,
        ),
        shareableField(id: 'last_name', label: 'Фамилия', value: _lastName),
        shareableField(
          id: 'display_name',
          label: 'Отображаемое имя',
          value: _displayName,
        ),
        shareableField(
          id: 'username',
          label: 'Имя пользователя',
          value: _username,
        ),
        shareableField(id: 'email', label: 'Электронная почта', value: _email),
        shareableField(id: 'phone', label: 'Телефон', value: _phone),
        shareableField(id: 'address', label: 'Адрес', value: _address),
        shareableField(
          id: 'birthday',
          label: 'Дата рождения',
          value: _fmt(_birthday),
        ),
        shareableField(id: 'company', label: 'Компания', value: _company),
        shareableField(id: 'job_title', label: 'Должность', value: _jobTitle),
        shareableField(id: 'website', label: 'Веб-сайт', value: _website),
        shareableField(
          id: 'tax_id',
          label: 'ИНН',
          value: _taxId,
          isSensitive: true,
        ),
        shareableField(
          id: 'national_id',
          label: 'СНИЛС/Паспорт РФ',
          value: _nationalId,
          isSensitive: true,
        ),
        shareableField(
          id: 'passport_number',
          label: 'Загранпаспорт',
          value: _passportNumber,
          isSensitive: true,
        ),
        shareableField(
          id: 'driver_license',
          label: 'Водительские права',
          value: _driverLicenseNumber,
          isSensitive: true,
        ),
        shareableField(
          id: 'description',
          label: l10n.description_label,
          value: _description,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: _name,
        entityTypeLabel: EntityType.identity.label,
        fields: fields,
      ),
    );
  }

  Widget _info(ThemeData theme, IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(l10n.view_identity),
        actions: [
          IconButton(
            tooltip: l10n.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: _isDeleted
                ? null
                : () => context.push(
                    AppRoutesPaths.dashboardEntityEdit(
                      EntityType.identity,
                      widget.identityId,
                    ),
                  ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  if (_displayName?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.person,
                      'Отображаемое имя',
                      _displayName!,
                    ),
                  if (_firstName?.isNotEmpty == true)
                    _info(theme, Icons.person_outline, 'Имя', _firstName!),
                  if (_middleName?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.person_outline,
                      'Отчество',
                      _middleName!,
                    ),
                  if (_lastName?.isNotEmpty == true)
                    _info(theme, Icons.person_outline, 'Фамилия', _lastName!),
                  if (_username?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.account_circle,
                      'Имя пользователя',
                      _username!,
                    ),
                  if (_email?.isNotEmpty == true)
                    _info(theme, Icons.email, 'Электронная почта', _email!),
                  if (_phone?.isNotEmpty == true)
                    _info(theme, Icons.phone, 'Телефон', _phone!),
                  if (_address?.isNotEmpty == true)
                    _info(theme, Icons.home, 'Адрес', _address!),
                  if (_birthday != null)
                    _info(theme, Icons.cake, 'Дата рождения', _fmt(_birthday)),
                  if (_company?.isNotEmpty == true)
                    _info(theme, Icons.business, 'Компания', _company!),
                  if (_jobTitle?.isNotEmpty == true)
                    _info(theme, Icons.work, 'Должность', _jobTitle!),
                  if (_website?.isNotEmpty == true)
                    _info(theme, Icons.web, 'Веб-сайт', _website!),
                  if (_taxId?.isNotEmpty == true)
                    _info(theme, Icons.assignment, 'ИНН', _taxId!),
                  if (_nationalId?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.assignment_ind,
                      'СНИЛС/Паспорт РФ',
                      _nationalId!,
                    ),
                  if (_passportNumber?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.badge,
                      'Загранпаспорт',
                      _passportNumber!,
                    ),
                  if (_driverLicenseNumber?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.drive_eta,
                      'Водительские права',
                      _driverLicenseNumber!,
                    ),
                  if (_description?.isNotEmpty == true)
                    _info(
                      theme,
                      Icons.description,
                      l10n.description_label,
                      _description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.identityId),
                ],
              ),
      ),
    );
  }
}
