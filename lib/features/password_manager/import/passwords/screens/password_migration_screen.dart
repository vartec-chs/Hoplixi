import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/import/passwords/providers/password_migration_provider.dart';
import 'package:hoplixi/main_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class PasswordMigrationScreen extends ConsumerStatefulWidget {
  const PasswordMigrationScreen({super.key});

  @override
  ConsumerState<PasswordMigrationScreen> createState() =>
      _PasswordMigrationScreenState();
}

class _PasswordMigrationScreenState
    extends ConsumerState<PasswordMigrationScreen> {
  final _batchCountController = TextEditingController(text: '3');
  final List<_PasswordDraftControllers> _drafts = [];

  @override
  void initState() {
    super.initState();
    _drafts.add(_PasswordDraftControllers());
  }

  @override
  void dispose() {
    _batchCountController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addSingleDraft() {
    ref.read(passwordMigrationProvider.notifier).clearMessage();
    setState(() {
      _drafts.add(_PasswordDraftControllers());
    });
  }

  void _addBatchDrafts() {
    final count = int.tryParse(_batchCountController.text);
    if (count == null || count <= 0) {
      ref
          .read(passwordMigrationProvider.notifier)
          .setError('Укажите корректное количество карточек больше 0.');
      return;
    }

    ref.read(passwordMigrationProvider.notifier).clearMessage();
    setState(() {
      _drafts.addAll(List.generate(count, (_) => _PasswordDraftControllers()));
    });
  }

  void _removeDraft(int index) {
    ref.read(passwordMigrationProvider.notifier).clearMessage();

    setState(() {
      if (_drafts.length == 1) {
        _drafts.first.clearAllFields();
        _drafts.first.clearErrors();
        return;
      }

      final removedDraft = _drafts.removeAt(index);
      removedDraft.dispose();
    });
  }

  void _resetDrafts({bool clearMessage = true}) {
    if (clearMessage) {
      ref.read(passwordMigrationProvider.notifier).clearMessage();
    }

    setState(() {
      for (final draft in _drafts) {
        draft.dispose();
      }

      _drafts
        ..clear()
        ..add(_PasswordDraftControllers());
      _batchCountController.text = '3';
    });
  }

  List<CreatePasswordDto>? _collectValidPasswords() {
    var hasValidationErrors = false;
    final passwords = <CreatePasswordDto>[];

    for (final draft in _drafts) {
      final isValid = draft.validate();
      if (!isValid) {
        hasValidationErrors = true;
        continue;
      }

      if (!draft.isEmpty) {
        passwords.add(draft.toDto());
      }
    }

    setState(() {});

    if (hasValidationErrors) {
      ref
          .read(passwordMigrationProvider.notifier)
          .setError('Проверьте обязательные поля в отмеченных карточках.');
      return null;
    }

    return passwords;
  }

  Future<void> _importPasswords() async {
    ref.read(passwordMigrationProvider.notifier).clearMessage();

    final passwords = _collectValidPasswords();
    if (passwords == null || passwords.isEmpty) {
      if (passwords != null) {
        ref
            .read(passwordMigrationProvider.notifier)
            .setError('Заполните хотя бы одну карточку перед импортом.');
      }
      return;
    }

    final isConfirmed = await _showPreviewDialog(passwords);
    if (!isConfirmed || !mounted) {
      return;
    }

    final isSaved = await ref
        .read(passwordMigrationProvider.notifier)
        .savePasswords(passwords);

    if (!mounted || !isSaved) {
      return;
    }

    ref
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerEntityAdd(EntityType.password);

    _resetDrafts(clearMessage: false);
  }

  Future<bool> _showPreviewDialog(List<CreatePasswordDto> passwords) async {
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Импортировать ${passwords.length} паролей?'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: passwords.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final password = passwords[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(password.name),
                    subtitle: Text(
                      password.login ?? password.email ?? 'Без логина и email',
                    ),
                    trailing: const Icon(Icons.lock_outline, size: 18),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Импортировать'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordMigrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Миграция паролей'),
        leading: const FormCloseButton(),
      ),
      body: state.maybeWhen(
        loading: () => const Center(child: CircularProgressIndicator()),
        orElse: () {
          final value = state.value;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        SizeTransition(sizeFactor: animation, child: child),
                    child: value?.message == null
                        ? const SizedBox.shrink(key: ValueKey('message-hidden'))
                        : Column(
                            key: const ValueKey('message-visible'),
                            children: [
                              NotificationCard(
                                type: value!.isSuccess
                                    ? NotificationType.success
                                    : NotificationType.error,
                                text: value.message!,
                                onDismiss: () {
                                  ref
                                      .read(passwordMigrationProvider.notifier)
                                      .clearMessage();
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                  ),
                  const InfoNotificationCard(
                    text:
                        'Пароли больше не импортируются через JSON-файл. '
                        'Создавайте карточки прямо на экране и сохраняйте их сразу в хранилище.',
                  ),
                  const SizedBox(height: 12),
                  _buildQuickCreateSection(),
                  const SizedBox(height: 12),
                  _buildDraftsSection(),
                  const SizedBox(height: 12),
                  _buildActionSection(isSaving: value?.isLoading ?? false),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickCreateSection() {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Быстрое добавление карточек', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Сейчас на экране карточек: ${_drafts.length}. '
              'Пустые карточки при импорте будут пропущены.',
              style: subtitleStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _batchCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: primaryInputDecoration(
                context,
                labelText: 'Количество новых карточек',
                hintText: '3',
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Добавить несколько карточек',
                onPressed: _addBatchDrafts,
                type: SmoothButtonType.filled,
                icon: const Icon(Icons.add_box_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Добавить одну карточку',
                onPressed: _addSingleDraft,
                type: SmoothButtonType.outlined,
                icon: const Icon(Icons.add, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsSection() {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Карточки для импорта', style: titleStyle),
            const SizedBox(height: 8),
            const Text(
              'Для каждой записи обязательны название, пароль и хотя бы одно поле: логин или email.',
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _drafts.length; index++) ...[
              _PasswordDraftCard(
                key: ObjectKey(_drafts[index]),
                index: index,
                draft: _drafts[index],
                canRemove: _drafts.length > 1,
                onRemove: () => _removeDraft(index),
                onChanged: () {
                  ref.read(passwordMigrationProvider.notifier).clearMessage();
                  setState(() {});
                },
                onTogglePasswordVisibility: () {
                  setState(() {
                    _drafts[index].obscurePassword =
                        !_drafts[index].obscurePassword;
                  });
                },
              ),
              if (index != _drafts.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection({required bool isSaving}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmoothButton(
              label: 'Импортировать в хранилище',
              onPressed: isSaving ? null : _importPasswords,
              type: SmoothButtonType.filled,
              loading: isSaving,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Очистить карточки',
              onPressed: isSaving ? null : () => _resetDrafts(),
              type: SmoothButtonType.outlined,
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordDraftCard extends StatelessWidget {
  final int index;
  final _PasswordDraftControllers draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onTogglePasswordVisibility;

  const _PasswordDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final borderColor = draft.hasErrors
        ? cardTheme.colorScheme.error.withValues(alpha: 0.35)
        : cardTheme.colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Карточка ${index + 1}',
                  style: cardTheme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: canRemove ? 'Удалить карточку' : 'Очистить карточку',
                icon: Icon(
                  canRemove ? Icons.delete_outline : Icons.cleaning_services,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.nameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Например, GitHub',
              errorText: draft.nameError,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            onChanged: (_) {
              draft.nameError = null;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.passwordController,
            obscureText: draft.obscurePassword,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Пароль',
              hintText: 'Введите пароль',
              errorText: draft.passwordError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onTogglePasswordVisibility,
                icon: Icon(
                  draft.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onChanged: (_) {
              draft.passwordError = null;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.loginController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Логин',
              hintText: 'Например, ivan.petrov',
              errorText: draft.accountError,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: (_) {
              draft.accountError = null;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Email',
              hintText: 'Например, user@example.com',
              errorText: draft.accountError,
              prefixIcon: const Icon(Icons.alternate_email),
            ),
            onChanged: (_) {
              draft.accountError = null;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Заполните логин или email. Можно заполнить оба поля.',
            style: cardTheme.textTheme.bodySmall?.copyWith(
              color: cardTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.urlController,
            keyboardType: TextInputType.url,
            decoration: primaryInputDecoration(
              context,
              labelText: 'URL',
              hintText: 'https://example.com',
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.descriptionController,
            maxLines: 2,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание',
              hintText: 'Необязательный комментарий',
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _PasswordDraftControllers {
  _PasswordDraftControllers()
    : nameController = TextEditingController(),
      passwordController = TextEditingController(),
      loginController = TextEditingController(),
      emailController = TextEditingController(),
      urlController = TextEditingController(),
      descriptionController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController loginController;
  final TextEditingController emailController;
  final TextEditingController urlController;
  final TextEditingController descriptionController;

  bool obscurePassword = true;

  String? nameError;
  String? passwordError;
  String? accountError;

  bool get hasErrors =>
      nameError != null || passwordError != null || accountError != null;

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      passwordController.text.trim().isEmpty &&
      loginController.text.trim().isEmpty &&
      emailController.text.trim().isEmpty &&
      urlController.text.trim().isEmpty &&
      descriptionController.text.trim().isEmpty;

  bool validate() {
    clearErrors();

    if (isEmpty) {
      return true;
    }

    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final login = loginController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      nameError = 'Укажите название.';
    }

    if (password.isEmpty) {
      passwordError = 'Укажите пароль.';
    }

    if (login.isEmpty && email.isEmpty) {
      accountError = 'Укажите логин или email.';
    }

    return !hasErrors;
  }

  CreatePasswordDto toDto() {
    return CreatePasswordDto(
      name: nameController.text.trim(),
      password: passwordController.text.trim(),
      login: _normalize(loginController.text),
      email: _normalize(emailController.text),
      url: _normalize(urlController.text),
      description: _normalize(descriptionController.text),
    );
  }

  void clearAllFields() {
    nameController.clear();
    passwordController.clear();
    loginController.clear();
    emailController.clear();
    urlController.clear();
    descriptionController.clear();
  }

  void clearErrors() {
    nameError = null;
    passwordError = null;
    accountError = null;
  }

  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    loginController.dispose();
    emailController.dispose();
    urlController.dispose();
    descriptionController.dispose();
  }

  String? _normalize(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
