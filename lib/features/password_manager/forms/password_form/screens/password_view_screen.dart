import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
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
  PasswordsData? _password;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];
  String? _noteName;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    try {
      final dao = await ref.read(passwordDaoProvider.future);
      final password = await dao.getPasswordById(widget.passwordId);

      if (password != null && mounted) {
        setState(() {
          _password = password;
          _isLoading = false;
        });
        await _loadRelatedData(password);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(PasswordsData password) async {
    if (password.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(password.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final dao = await ref.read(passwordDaoProvider.future);
    final tagIds = await dao.getPasswordTagIds(widget.passwordId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }

    if (password.noteId != null) {
      final noteDao = await ref.read(noteDaoProvider.future);
      final note = await noteDao.getNoteById(password.noteId!);
      if (mounted && note != null) setState(() => _noteName = note.title);
    }
  }

  void _copy(String v, String f) {
    Clipboard.setData(ClipboardData(text: v));
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.password, widget.passwordId),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_password?.name ?? 'Пароль'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Редактировать',
            onPressed: _edit,
          ),
        ],
      ),
      body: _isLoading
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
                  _password!.name,
                  () => _copy(_password!.name, 'Название'),
                ),
                _passwordField(theme),
                if (_password!.login?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.user,
                    'Логин',
                    _password!.login!,
                    () => _copy(_password!.login!, 'Логин'),
                  ),
                if (_password!.email?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.mail,
                    'Email',
                    _password!.email!,
                    () => _copy(_password!.email!, 'Email'),
                  ),
                if (_password!.url?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.globe,
                    'URL',
                    _password!.url!,
                    () => _copy(_password!.url!, 'URL'),
                  ),
                if (_categoryName != null)
                  _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                if (_tagNames.isNotEmpty) _tags(theme),
                if (_password!.description?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.fileText,
                    'Описание',
                    _password!.description!,
                  ),
                if (_noteName != null)
                  _info(theme, LucideIcons.stickyNote, 'Заметка', _noteName!),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(LucideIcons.pencil),
                  label: const Text('Редактировать'),
                ),
              ],
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
          _obscurePassword ? '••••••••••••' : _password!.password,
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
              onPressed: () => _copy(_password!.password, 'Пароль'),
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
