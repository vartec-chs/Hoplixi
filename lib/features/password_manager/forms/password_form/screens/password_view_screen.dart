import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_viewer.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Экран просмотра пароля (только чтение, с возможностью копирования)
class PasswordViewScreen extends ConsumerStatefulWidget {
  const PasswordViewScreen({super.key, required this.passwordId});

  final String passwordId;

  @override
  ConsumerState<PasswordViewScreen> createState() => _PasswordViewScreenState();
}

class _PasswordViewScreenState extends ConsumerState<PasswordViewScreen> {
  bool _obscurePassword = true;
  PasswordViewDto? _password;
  bool _isDeleted = false;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];
  String? _noteName;
  List<CustomFieldEntry> _customFields = [];

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    try {
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.password.getViewById(
        widget.passwordId,
      );
      final view = viewResult.getOrNull()?.getOrNull();

      if (view != null && mounted) {
        setState(() {
          _password = view;
          _isDeleted = view.item.isDeleted;
          _isLoading = false;
        });
        await _loadRelatedData(view, repositories);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    PasswordViewDto view,
    VaultRepositories repositories,
  ) async {
    if (view.item.categoryId != null) {
      final cat = (await repositories.category.getCategory(
        view.item.categoryId!,
      )).getOrNull()?.getOrNull();
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final tagIds =
        (await relationsService.getTagIdsForItem(
          widget.passwordId,
        )).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }

    // TODO: Load Note details using ItemLinkRepository or RelationsService
    // if (view.item.noteId != null) { ... }

    final customFieldsRes = await repositories.vaultItemCustomFields
        .getByItemId(widget.passwordId);
    final rows = customFieldsRes.getOrNull() ?? [];
    if (mounted) {
      setState(
        () => _customFields = rows
            .map((r) => CustomFieldEntry.fromData(r))
            .toList(),
      );
    }
  }

  Future<void> _copy(String v, String f) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.passwordId,
      text: v,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.password, widget.passwordId),
  );

  Future<void> _share() async {
    final record = _password;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    final fields = [
      ...buildCommonShareFields(
        context,
        name: record.item.name,
        categoryName: _categoryName,
        tagNames: _tagNames,
        description: record.item.description,
        customFields: _customFields,
      ),
      ...compactShareableFields([
        shareableField(
          id: 'password',
          label: l10n.password_label,
          value: record.password.password,
          isSensitive: true,
        ),
        shareableField(
          id: 'login',
          label: l10n.login_label,
          value: record.password.login,
        ),
        shareableField(
          id: 'email',
          label: l10n.email_label,
          value: record.password.email,
        ),
        shareableField(
          id: 'url',
          label: l10n.url_label,
          value: record.password.url,
        ),
        shareableField(
          id: 'note',
          label: l10n.share_linked_note_label,
          value: _noteName,
        ),
      ]),
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.password.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_password?.item.name ?? 'Пароль'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _password == null
                ? null
                : _share,
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Редактировать',
            onPressed: _isDeleted ? null : _edit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _password == null
            ? const Center(child: Text('Не найден'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _info(
                    theme,
                    LucideIcons.tag,
                    'Название',
                    _password!.item.name,
                    () => _copy(_password!.item.name, 'Название'),
                  ),
                  _passwordField(theme),
                  if (_password!.password.login?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.user,
                      'Логин',
                      _password!.password.login!,
                      () => _copy(_password!.password.login!, 'Логин'),
                    ),
                  if (_password!.password.email?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.mail,
                      'Email',
                      _password!.password.email!,
                      () => _copy(_password!.password.email!, 'Email'),
                    ),
                  if (_password!.password.url?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.globe,
                      'URL',
                      _password!.password.url!,
                      () => _copy(_password!.password.url!, 'URL'),
                    ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_password!.item.description?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _password!.item.description!,
                    ),
                  if (_noteName != null)
                    _info(theme, LucideIcons.stickyNote, 'Заметка', _noteName!),
                  if (_customFields.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    CustomFieldsViewer(fields: _customFields),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _passwordField(ThemeData t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(LucideIcons.lock, color: t.colorScheme.primary),
        title: Text('Пароль', style: t.textTheme.bodySmall),
        subtitle: Text(
          _obscurePassword ? '••••••••••••' : _password!.password.password,
          style: t.textTheme.bodyLarge,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            IconButton(
              icon: const Icon(LucideIcons.copy),
              onPressed: () => _copy(_password!.password.password, 'Пароль'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(ThemeData t, IconData i, String l, String v, [VoidCallback? c]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(i, color: t.colorScheme.primary),
        title: Text(l, style: t.textTheme.bodySmall),
        subtitle: Text(v, style: t.textTheme.bodyLarge),
        trailing: c != null
            ? IconButton(icon: const Icon(LucideIcons.copy), onPressed: c)
            : null,
      ),
    );
  }

  Widget _tags(ThemeData t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.tags, color: t.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Теги', style: t.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tagNames.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
